import requests
from datetime import datetime, timedelta

# 1. HARDCODED DATABASES
CROP_DATABASE = {
    "Tomatoes": {"initial": 0.60, "mid": 1.15, "late": 0.80},
    "Maize (Corn)": {"initial": 0.30, "mid": 1.20, "late": 0.35},
    "Potatoes": {"initial": 0.50, "mid": 1.15, "late": 0.75},
    "Wheat": {"initial": 0.30, "mid": 1.15, "late": 0.25},
    "Citrus Trees": {"initial": 0.75, "mid": 0.75, "late": 0.75}
}

SOIL_DATABASE = {
    "Sand": 65,
    "Loam": 80,
    "Clay": 85
}

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

# 3. FAO-56 & EFFECTIVE RAIN CALCULATOR
class IrrigationEngine:
    def __init__(self, crop_kc, soil_type):
        self.kc = crop_kc
        self.soil_type = soil_type
        self.base_cn = SOIL_DATABASE.get(soil_type, 80)

    def get_amc_condition(self, weather_data, mode):
        if not weather_data: return "II", 0
        
        if mode == "Hybrid" and "hourly" in weather_data:
            latest_vwc = weather_data['hourly']['soil_moisture_0_to_10cm'][-1]
            if latest_vwc < 0.15: return "I", latest_vwc
            if latest_vwc > 0.35: return "III", latest_vwc
            return "II", latest_vwc
        
        if "daily" in weather_data:
            total_rain = sum(weather_data['daily']['precipitation_sum'])
            if total_rain < 13: return "I", total_rain
            if total_rain > 38: return "III", total_rain
        return "II", 0

    def calculate_effective_rain(self, rain_mm, amc):
        if rain_mm <= 2.0: return 0.0
        # USDA CN Adjustment formulas
        if amc == "I": cn = self.base_cn / (2.281 - 0.01281 * self.base_cn)
        elif amc == "III": cn = self.base_cn / (0.427 + 0.00573 * self.base_cn)
        else: cn = self.base_cn
        
        s = (25400 / cn) - 254
        ia = 0.2 * s
        if rain_mm <= ia: return rain_mm
        return max(0, rain_mm - (((rain_mm - ia) ** 2) / (rain_mm + 0.8 * s)))

    def run_fao56_logic(self, weather_data, mode="Hybrid"):
        # Display Fetched Data Log
        print("\nENVIRONMENTAL DATA LOG")
        dates = weather_data['daily'].get('time', [])
        rains = weather_data['daily'].get('precipitation_sum', [])
        
        if len(rains) > 1:
            print("5-Day Rainfall History:")
            for d, r in zip(dates, rains):
                print(f"  > {d}: {r} mm")
        else:
            print(f"  Yesterday's Rain: {rains[-1]} mm")

        raw_rain = rains[-1]
        et0 = weather_data['daily']['et0_fao_evapotranspiration'][-1]
        amc, sensor_val = self.get_amc_condition(weather_data, mode)
        
        if mode == "Hybrid":
            print(f"  Latest Soil Moisture: {sensor_val} m3/m3")
        else:
            print(f"  5-Day Total Rain for AMC: {sensor_val} mm")

        # Calculations
        eff_rain = self.calculate_effective_rain(raw_rain, amc)
        crop_water_loss = et0 * self.kc
        irrigation_needed = max(0.0, crop_water_loss - eff_rain)

        print("\nAPP DASHBOARD: FAO-56 & USDA ENGINE")
        print(f"Mode: {mode} | Soil: {self.soil_type} | AMC: {amc}")
        print(f"$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$$")
        print(f"Reference ET0:       {round(et0, 2)} mm")
        print(f"Effective Rain:     -{round(eff_rain, 2)} mm")
        print(f"WATER TO DISPENSE:   {round(irrigation_needed, 2)} mm")
        
        return round(irrigation_needed, 2)

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
    
    engine = IrrigationEngine(crop_kc=1.15, soil_type="Clay")
    engine.run_fao56_logic(weather_package, mode=calc_mode)

if __name__ == "__main__":
    run_app_cycle()