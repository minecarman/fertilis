from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pathlib import Path
import csv
from typing import Optional
import requests
from crop_recommendation.predict_crop import CropRecommender
from crop_recommendation.soilgrids_service import get_soil_and_climate_data
from irrigation.irrigation_engine import DataOrchestrator, IrrigationEngine, SOIL_DATABASE
from yield_recommendation import YieldPredictor

app = FastAPI(title="Fertilis AI Microservice")

try:
    model_path = Path(__file__).parent / "crop_recommendation" / "models" / "crop_model.pkl"
    recommender = CropRecommender(str(model_path))
except Exception as e:
    recommender = None
    print(f"Warning: Could not load the crop recommendation model: {e}")

try:
    yield_model_path = Path(__file__).parent / "yield_recommendation" / "model" / "amis_model.joblib"
    yield_data_path = Path(__file__).parent / "yield_recommendation" / "data" / "data_clean.csv"
    yield_predictor = YieldPredictor(model_path=str(yield_model_path), data_path=str(yield_data_path))
except Exception as e:
    yield_predictor = None
    print(f"Warning: Could not load the yield model: {e}")

class LocationRequest(BaseModel):
    lat: float
    lng: float


class IrrigationRequest(BaseModel):
    lat: float
    lng: float
    crop: str = "tomato"
    crop_kc: Optional[float] = None
    soil_type: str = "Clay"
    mode: str = "Hybrid"
    last_irrigated_days: int = 0


class YieldPredictionRequest(BaseModel):
    commodity: str
    country: Optional[str] = None
    lat: Optional[float] = None
    lng: Optional[float] = None


def resolve_country_from_coordinates(lat: float, lng: float) -> Optional[str]:
    url = "https://nominatim.openstreetmap.org/reverse"
    params = {
        "lat": lat,
        "lon": lng,
        "format": "jsonv2",
        "accept-language": "en",
    }
    headers = {"User-Agent": "fertilis-ml-service/1.0"}

    try:
        response = requests.get(url, params=params, headers=headers, timeout=10)
        response.raise_for_status()
        payload = response.json()
        return payload.get("address", {}).get("country")
    except Exception:
        return None


def normalize_country_name(country: str) -> str:
    normalized = country.strip()
    aliases = {
        "Turkey": "T\u00fcrkiye",
        "Turkiye": "T\u00fcrkiye",
        "T\u00fcrkiye": "T\u00fcrkiye",
    }
    return aliases.get(normalized, normalized)


def normalize_crop_name(crop_name: Optional[str]) -> Optional[str]:
    if crop_name is None:
        return None

    normalized = crop_name.strip().lower()
    if not normalized:
        return None

    aliases = {
        "maize (corn)": "maize",
        "tomatoes": "tomato",
        "potatoes": "potato",
        "citrus trees": "citrus",
    }
    return aliases.get(normalized, normalized)


def load_crop_days() -> dict:
    days_path = Path(__file__).parent / "irrigation" / "data" / "days.csv"
    crop_days = {}

    try:
        with days_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                crop_key = normalize_crop_name(row.get("crop"))
                if not crop_key:
                    continue

                try:
                    crop_days[crop_key] = int(float(row.get("days", 0)))
                except (TypeError, ValueError):
                    continue
    except FileNotFoundError:
        print(f"Warning: irrigation day schedule not found at {days_path}")

    return crop_days


CROP_IRRIGATION_DAYS = load_crop_days()

def load_crop_kc() -> dict:
    """Load crop coefficients: both single Kc and basal Kcb for dual coefficient mode."""
    kc_path = Path(__file__).parent / "irrigation" / "data" / "crop_kc.csv"
    kc_data = {}
    try:
        with kc_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                crop_key = row.get("crop")
                if crop_key:
                    kc_data[crop_key] = {
                        "kc": float(row.get("kc", 1.0)),
                        "kcb": float(row.get("kcb", float(row.get("kc", 1.0)) - 0.15)),
                    }
    except FileNotFoundError:
        print(f"Warning: crop kc database not found at {kc_path}")
    return kc_data

CROP_KC_BY_NAME = load_crop_kc()


def _irrigation_decision(irrigation_mm: float) -> str:
    if irrigation_mm <= 0:
        return "Bugun sulamaya gerek yok"
    if irrigation_mm < 2:
        return "Az miktarda sulama yap"
    return "Sulama gerekli"

def load_planting_calendar() -> dict:
    calendar_path = Path(__file__).parent / "crop_recommendation" / "data" / "planting_calendar.csv"
    calendar_data = {}
    try:
        with calendar_path.open("r", encoding="utf-8", newline="") as handle:
            reader = csv.DictReader(handle)
            for row in reader:
                crop_key = normalize_crop_name(row.get("crop"))
                if crop_key:
                    calendar_data[crop_key] = row.get("calendar", "")
    except FileNotFoundError:
        print(f"Warning: planting calendar not found at {calendar_path}")
    return calendar_data

PLANTING_CALENDAR = load_planting_calendar()

def get_planting_calendar(crop_name):
    normalized = normalize_crop_name(crop_name)
    return PLANTING_CALENDAR.get(normalized, "Genellikle ilkbaharda, don tehlikesi geçtikten sonra ekimi tavsiye edilir.")

@app.post("/recommend_by_location")
def recommend_by_location(data: LocationRequest):
    if not recommender:
        raise HTTPException(status_code=503, detail="Model is not loaded")
    try:
        features = get_soil_and_climate_data(data.lat, data.lng)
        
        result = recommender.predict(
            N=features["N"], P=features["P"], K=features["K"], 
            temperature=features["temperature"], humidity=features["humidity"],
            ph=features["ph"], rainfall=features["rainfall"]
        )
        
        # Add planting calendar info directly into the array returned to Node
        for r in result:
            r['planting_calendar'] = get_planting_calendar(r['crop'])
            
        return {
            "status": "success",
            "features": features,
            "recommendation": result
        }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/irrigation/recommend")
def recommend_irrigation(data: IrrigationRequest):
    """
    Core API Endpoint for calculating Precision Irrigation Recommendations.
    
    This orchestrates the physical hydrology calculations by:
    1. Looking up crop-specific physiological data (Base Kc, Transpiration coefficients, irrigation thresholds).
    2. Looking up physical soil properties (Curve Number, Field Capacity, Wilting Point).
    3. Querying real-time satellite environmental data (ET0, Rainfall, Volumetric Water Content) via Open-Meteo or NASA POWER.
    4. Passing the aggregated datasets into the FAO-56 Dual Crop Coefficient physical engine.
    """
    try:
        # Step 1: Normalize and fetch crop static tables
        crop_key = normalize_crop_name(data.crop) or "tomato"
        recommended_days = CROP_IRRIGATION_DAYS.get(crop_key, 7)
        last_irrigated_days = max(0, int(data.last_irrigated_days))

        # Step 2: Resolve soil physical parameters
        soil_map = {name.lower(): name for name in SOIL_DATABASE.keys()}
        soil_key = soil_map.get(data.soil_type.lower())
        if not soil_key:
            raise HTTPException(status_code=400, detail=f"Unsupported soil_type: {data.soil_type}")

        mode = data.mode.capitalize()
        if mode not in {"Hybrid", "Strict"}:
            raise HTTPException(status_code=400, detail="mode must be 'Hybrid' or 'Strict'")

        # Step 3: Fetch Environmental Telemetry (Live weather, ET0, Satellite Soil Moisture)
        orchestrator = DataOrchestrator(lat=data.lat, lon=data.lng)
        weather_data = orchestrator.fetch_weather_package()
        weather_source = "open-meteo"
        
        # Fallback to NASA POWER if primary meteorology source fails
        if not weather_data:
            weather_data = orchestrator.fetch_nasa_fallback()
            weather_source = "nasa-power"

        if not weather_data:
            raise HTTPException(status_code=503, detail="Could not fetch weather data from providers")

        # Step 4: Resolve biological coefficients for the specific crop
        crop_coeffs = CROP_KC_BY_NAME.get(crop_key, {"kc": 1.15, "kcb": 1.00})
        if data.crop_kc is not None:
            # User explicitly provided a single Kc override — mathematically derive Kcb
            crop_kc = data.crop_kc
            crop_kcb = max(0.1, crop_kc - 0.15)
        else:
            crop_kc = crop_coeffs["kc"]
            crop_kcb = crop_coeffs["kcb"]

        # Step 5: Execute the physical calculation engine
        engine = IrrigationEngine(crop_kcb=crop_kcb, crop_kc=crop_kc, soil_type=soil_key)
        result = engine.run_fao56_logic(weather_data, mode=mode, verbose=False)
        
        # Step 6: Decorate the final JSON response with metadata for the Flutter client
        result["weather_source"] = weather_source
        result["crop"] = crop_key
        result["crop_kc"] = round(float(crop_kc), 2)
        result["crop_kcb"] = round(float(crop_kcb), 3)
        result["recommended_irrigation_days"] = recommended_days
        result["last_irrigated_days"] = last_irrigated_days

        base_irrigation = float(result["irrigation_mm"])

        # Determine binary decision string based on mathematical outputs
        personalized_irrigation = round(base_irrigation, 2)
        decision = result.get("decision", "Sulama gerekli" if personalized_irrigation > 0 else "Bugun sulamaya gerek yok")
        
        if personalized_irrigation > 0:
            schedule_status = "Sulama gerekli"
            timing_factor = 1.0
        else:
            schedule_status = "Sulama gereksiz"
            timing_factor = 0.0

        result["base_irrigation_mm"] = round(base_irrigation, 2)
        result["timing_factor"] = round(timing_factor, 2)
        result["schedule_status"] = schedule_status
        result["decision"] = decision
        result["irrigation_mm"] = personalized_irrigation

        # Temporary compatibility fields while frontend migrates to the new contract.
        result["rain"] = f"{result['raw_rain_mm']:.2f}"

        return result
    except HTTPException:
        raise
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@app.post("/yield/predict")
def predict_yield(data: YieldPredictionRequest):
    if not yield_predictor:
        raise HTTPException(status_code=503, detail="Yield model is not loaded")

    input_mode = "country"
    country = data.country

    if not country:
        if data.lat is None or data.lng is None:
            raise HTTPException(status_code=400, detail="Provide either country or both lat/lng")
        country = resolve_country_from_coordinates(data.lat, data.lng)
        if not country:
            raise HTTPException(status_code=400, detail="Could not resolve country from coordinates")
        input_mode = "coordinates"

    country = normalize_country_name(country)

    try:
        prediction = yield_predictor.predict(country=country, commodity=data.commodity)
        return {
            "status": "success",
            "input_mode": input_mode,
            "resolved_country": country,
            "prediction": prediction,
        }
    except ValueError as e:
        raise HTTPException(status_code=404, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
