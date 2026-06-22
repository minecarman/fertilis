import requests
from datetime import datetime, timedelta
import csv
from pathlib import Path

def load_soil_database():
    """Load soil physical properties needed for both CN and Ke calculations.
    
    Returns dict: { "Clay": { "cn": 85, "tew": 14.0, "rew": 6.0, "fc": 0.36, "wp": 0.17 }, ... }
    """
    db_path = Path(__file__).parent / "data" / "soil_database.csv"
    soil_db = {}
    try:
        with db_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                soil_key = row.get("soil")
                if soil_key:
                    soil_db[soil_key] = {
                        "cn": int(row.get("cn", 80)),
                        "tew": float(row.get("tew", 12.0)),
                        "rew": float(row.get("rew", 5.0)),
                        "fc": float(row.get("fc", 0.28)),
                        "wp": float(row.get("wp", 0.10)),
                    }
    except FileNotFoundError:
        print(f"Warning: soil database not found at {db_path}")
    return soil_db

SOIL_DATABASE = load_soil_database()


def _safe_last(values, default=0.0):
    if not values:
        return default
    valid_values = [v for v in values if v is not None]
    if not valid_values:
        return default
    return valid_values[-1]


def _irrigation_decision(irrigation_mm):
    if irrigation_mm <= 0:
        return "Bugun sulamaya gerek yok"
    if irrigation_mm < 2:
        return "Az miktarda sulama yap"
    return "Sulama gerekli"


# 2. DATA ORCHESTRATOR
class DataOrchestrator:
    def __init__(self, lat, lon):
        self.lat = lat
        self.lon = lon

    def fetch_weather_package(self):
        print(f"Data Flow: Fetching 5-day Package for Lat:{self.lat}, Lon:{self.lon}...")
        end_date = datetime.now() - timedelta(days=1)
        start_date = end_date - timedelta(days=4)
        
        url = "https://api.open-meteo.com/v1/forecast"
        params = {
            "latitude": self.lat, "longitude": self.lon,
            "daily": ["precipitation_sum", "et0_fao_evapotranspiration"],
            "hourly": ["soil_moisture_0_to_10cm"],
            "start_date": start_date.strftime("%Y-%m-%d"),
            "end_date": end_date.strftime("%Y-%m-%d"),
            "timezone": "auto"
        }
        try:
            response = requests.get(url, params=params, timeout=10)
            response.raise_for_status()
            return response.json()
        except Exception as e:
            print(f"Data Flow: Open-Meteo failed ({e}).")
            return None

    def fetch_nasa_fallback(self):
        print("Data Flow: Falling back to NASA POWER...")
        yesterday = (datetime.now() - timedelta(days=1)).strftime("%Y%m%d")
        url = "https://power.larc.nasa.gov/api/temporal/daily/point"
        params = {
            "parameters": "PRECTOTCORR,EVPTRNS",
            "community": "AG", "longitude": self.lon, "latitude": self.lat,
            "start": yesterday, "end": yesterday, "format": "JSON"
        }
        try:
            res = requests.get(url, params=params).json()
            rain = res['properties']['parameter']['PRECTOTCORR'].get(yesterday, 0.0)
            et0 = res['properties']['parameter']['EVPTRNS'].get(yesterday, 5.0)
            return {"daily": {"precipitation_sum": [rain], "et0_fao_evapotranspiration": [et0], "time": [yesterday]}}
        except:
            return None


# 3. FAO-56 DUAL CROP COEFFICIENT ENGINE
class IrrigationEngine:
    """Implements FAO-56 Dual Crop Coefficient (Kcb + Ke) with USDA-SCS Curve Number runoff.

    The single Kc approach lumps plant transpiration and soil evaporation together.
    The dual approach separates them:
        ETc = (Kcb + Ke) * ET0

    where:
        Kcb = Basal crop coefficient (transpiration only, from crop tables)
        Ke  = Soil evaporation coefficient (calculated from live soil moisture)
        ET0 = Reference evapotranspiration (from satellite/weather API)

    Ke is bounded by:  0 <= Ke <= few * Kc_max
    and reduced by Kr when the topsoil dries out below REW.

    References:
        FAO Irrigation & Drainage Paper 56, Chapter 7 (Eq. 71-79)
        USDA-SCS National Engineering Handbook, Part 630
    """

    def __init__(self, crop_kcb, crop_kc, soil_type):
        self.kcb = crop_kcb          # Basal crop coefficient (transpiration only)
        self.kc = crop_kc            # Single Kc (used as Kc_max ceiling & fallback)
        self.soil_type = soil_type

        soil_props = SOIL_DATABASE.get(soil_type, {})
        self.base_cn = soil_props.get("cn", 80)
        self.tew = soil_props.get("tew", 12.0)   # Total Evaporable Water (mm)
        self.rew = soil_props.get("rew", 5.0)     # Readily Evaporable Water (mm)
        self.fc = soil_props.get("fc", 0.28)       # Field Capacity (m3/m3)
        self.wp = soil_props.get("wp", 0.10)       # Wilting Point (m3/m3)

    # -----------------------------------------------------------------
    #  Ke Calculation  (FAO-56 Eq. 71-79)
    # -----------------------------------------------------------------
    def calculate_ke(self, et0, soil_moisture_vwc):
        """Calculate the soil evaporation coefficient Ke from live soil moisture.

        FAO-56 Chapter 7 defines:
            Ke = Kr * (Kc_max - Kcb)   bounded by   Ke <= few * Kc_max

        where:
            Kc_max = upper limit on (Kcb + Ke), typically max(1.2, Kcb + 0.05)
            few    = fraction of soil that is both exposed and wetted (0.01 - 1.0)
            Kr     = evaporation reduction coefficient (1.0 when wet, drops to 0 when dry)
        """
        if et0 <= 0:
            return 0.0, {}

        # Kc_max: FAO-56 Eq. 72 — upper limit on evapotranspiration
        kc_max = max(1.20, self.kcb + 0.05)

        # few: fraction of soil surface that is both exposed and wetted
        # For surface irrigation / rain, assume ~0.6-0.8 of soil surface is wetted.
        # For drip, this would be much lower (~0.3). Default to rain/sprinkler.
        fc_fraction = min(1.0, max(0.01, self.kcb / kc_max))  # approximate canopy fraction
        few = max(0.01, min(1.0, 1.0 - fc_fraction))

        # Kr: evaporation reduction coefficient (FAO-56 Eq. 74)
        # Estimate topsoil depletion (De) from live VWC sensor data.
        # De = 0 when soil is at field capacity, De = TEW when completely dry.
        if self.fc <= self.wp:
            # Degenerate soil data — fall back to Kr = 1.0
            kr = 1.0
            de = 0.0
        else:
            # Map the volumetric water content to depletion
            # When VWC = FC → De = 0 (fully wet topsoil)
            # When VWC = WP → De = TEW (bone dry topsoil)
            vwc_clamped = max(self.wp, min(self.fc, soil_moisture_vwc))
            fraction_depleted = 1.0 - (vwc_clamped - self.wp) / (self.fc - self.wp)
            de = fraction_depleted * self.tew

            # FAO-56 Eq. 74: Kr = (TEW - De) / (TEW - REW)
            if de <= self.rew:
                # Soil is still wet enough — no reduction
                kr = 1.0
            elif self.tew <= self.rew:
                kr = 0.0
            else:
                kr = max(0.0, (self.tew - de) / (self.tew - self.rew))

        # Ke: FAO-56 Eq. 71
        ke_energy = kr * (kc_max - self.kcb)
        ke_limit = few * kc_max
        ke = max(0.0, min(ke_energy, ke_limit))

        debug = {
            "kc_max": round(kc_max, 3),
            "few": round(few, 3),
            "kr": round(kr, 3),
            "de_mm": round(de, 2),
            "ke_energy": round(ke_energy, 3),
            "ke_limit": round(ke_limit, 3),
        }
        return ke, debug

    # -----------------------------------------------------------------
    #  AMC & Effective Rain  (unchanged from single-Kc version)
    # -----------------------------------------------------------------
    def get_amc_condition(self, weather_data, mode):
        if not weather_data:
            return "II", 0.0
        
        if mode == "Hybrid" and "hourly" in weather_data:
            moisture_values = weather_data.get('hourly', {}).get('soil_moisture_0_to_10cm', [])
            latest_vwc = _safe_last(moisture_values, 0.0)
            if latest_vwc < 0.15: return "I", latest_vwc
            if latest_vwc > 0.35: return "III", latest_vwc
            return "II", latest_vwc
        
        if "daily" in weather_data:
            rain_values = weather_data.get('daily', {}).get('precipitation_sum', [])
            valid_rains = [r for r in rain_values if r is not None]
            total_rain = float(sum(valid_rains))
            if total_rain < 13: return "I", total_rain
            if total_rain > 38: return "III", total_rain
        return "II", 0.0

    def calculate_effective_rain(self, rain_mm, amc):
        if rain_mm <= 2.0: return 0.0
        # USDA CN Adjustment formulas
        if amc == "I": cn = self.base_cn / (2.281 - 0.01281 * self.base_cn)
        elif amc == "III": cn = self.base_cn / (0.427 + 0.00573 * self.base_cn)
        else: cn = self.base_cn

        if cn <= 0 or cn >= 100:
            cn = max(1.0, min(cn, 99.0))

        s = (25400 / cn) - 254
        if s <= 0:
            return max(0.0, rain_mm)
        ia = 0.2 * s
        if rain_mm <= ia: return rain_mm
        denominator = rain_mm + 0.8 * s
        if denominator <= 0:
            return max(0.0, rain_mm)
        return max(0.0, rain_mm - (((rain_mm - ia) ** 2) / denominator))

    # -----------------------------------------------------------------
    #  Main Engine: Dual Coefficient Logic
    # -----------------------------------------------------------------
    def run_fao56_logic(self, weather_data, mode="Hybrid", verbose=False):
        daily_data = weather_data.get('daily', {}) if weather_data else {}
        dates = daily_data.get('time', [])
        rains = daily_data.get('precipitation_sum', [])
        et0_values = daily_data.get('et0_fao_evapotranspiration', [])

        raw_rain = float(_safe_last(rains, 0.0))
        et0 = float(_safe_last(et0_values, 0.0))
        amc, sensor_val = self.get_amc_condition(weather_data, mode)

        # Get live soil moisture for Ke calculation
        soil_moisture_vwc = 0.0
        if mode == "Hybrid" and weather_data and "hourly" in weather_data:
            moisture_values = weather_data.get('hourly', {}).get('soil_moisture_0_to_10cm', [])
            soil_moisture_vwc = float(_safe_last(moisture_values, self.fc))
        else:
            # No live sensor → assume field capacity (Ke will be maximized, conservative)
            soil_moisture_vwc = self.fc

        # --- DUAL COEFFICIENT CALCULATION ---
        # Kcb: basal transpiration (from crop tables)
        kcb_used = self.kcb

        # Ke: soil evaporation (calculated from live soil moisture)
        ke, ke_debug = self.calculate_ke(et0, soil_moisture_vwc)

        # ETc = (Kcb + Ke) * ET0
        transpiration_mm = kcb_used * et0
        evaporation_mm = ke * et0
        crop_water_loss = transpiration_mm + evaporation_mm

        # Effective rainfall (USDA CN, unchanged)
        eff_rain = self.calculate_effective_rain(raw_rain, amc)

        # Net irrigation requirement
        irrigation_needed = max(0.0, crop_water_loss - eff_rain)

        result = {
            "mode": mode,
            "method": "FAO-56 Dual Crop Coefficient",
            "soil_type": self.soil_type,
            "amc": amc,
            "amc_reference": round(float(sensor_val), 4),
            "raw_rain_mm": round(raw_rain, 2),
            "et0_mm": round(et0, 2),
            "effective_rain_mm": round(eff_rain, 2),
            "kcb": round(kcb_used, 3),
            "ke": round(ke, 3),
            "kc_effective": round(kcb_used + ke, 3),
            "transpiration_mm": round(transpiration_mm, 2),
            "evaporation_mm": round(evaporation_mm, 2),
            "crop_water_loss_mm": round(crop_water_loss, 2),
            "irrigation_mm": round(irrigation_needed, 2),
            "decision": _irrigation_decision(irrigation_needed),
            "ke_debug": ke_debug,
            "history": {
                "dates": dates,
                "rains_mm": [round(float(r), 2) for r in rains if r is not None],
            },
        }

        if verbose:
            print("\nENVIRONMENTAL DATA LOG")
            if len(rains) > 1:
                print("5-Day Rainfall History:")
                for d, r in zip(dates, rains):
                    if r is not None:
                        print(f"  > {d}: {r} mm")
            else:
                print(f"  Yesterday's Rain: {raw_rain} mm")

            if mode == "Hybrid":
                print(f"  Latest Soil Moisture: {soil_moisture_vwc:.3f} m3/m3")
            else:
                print(f"  5-Day Total Rain for AMC: {sensor_val} mm")

            print("\nFAO-56 DUAL COEFFICIENT ENGINE")
            print(f"Mode: {mode} | Soil: {self.soil_type} | AMC: {amc}")
            print(f"{'='*45}")
            print(f"Reference ET0:           {result['et0_mm']:>8.2f} mm")
            print(f"Kcb (Transpiration):     {result['kcb']:>8.3f}")
            print(f"Ke  (Soil Evaporation):  {result['ke']:>8.3f}")
            print(f"Kc  (Effective Total):   {result['kc_effective']:>8.3f}")
            print(f"{'─'*45}")
            print(f"Plant Transpiration:     {result['transpiration_mm']:>8.2f} mm")
            print(f"Soil Evaporation:        {result['evaporation_mm']:>8.2f} mm")
            print(f"Total Crop Water Loss:   {result['crop_water_loss_mm']:>8.2f} mm")
            print(f"Effective Rain:         -{result['effective_rain_mm']:>8.2f} mm")
            print(f"{'='*45}")
            print(f"IRRIGATION NEEDED:       {result['irrigation_mm']:>8.2f} mm")

        return result

# 4. MAIN APP EXECUTION
def run_app_cycle():
    # Simulation settings
    orchestrator = DataOrchestrator(lat=36.8969, lon=30.7133)
    weather_package = orchestrator.fetch_weather_package() or orchestrator.fetch_nasa_fallback()
    
    if not weather_package:
        print("Data failed.")
        return

    # Check if we have hourly data for Hybrid mode
    calc_mode = "Hybrid" if "hourly" in weather_package else "Strict"
    
    engine = IrrigationEngine(crop_kcb=1.00, crop_kc=1.15, soil_type="Clay")
    result = engine.run_fao56_logic(weather_package, mode=calc_mode, verbose=True)
    print(f"Decision: {result['decision']}")

if __name__ == "__main__":
    run_app_cycle()