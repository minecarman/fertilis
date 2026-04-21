from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pathlib import Path
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
    crop_kc: float = 1.15
    soil_type: str = "Clay"
    mode: str = "Hybrid"


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
        "Turkey": "Türkiye",
        "Turkiye": "Türkiye",
        "Türkiye": "Türkiye",
    }
    return aliases.get(normalized, normalized)

def get_planting_calendar(crop_name):
    # Basist Ekim takvimi kurali
    calendar = {
        'wheat': 'Buğday: (Kışlık) için Eylül sonu - Kasım arası, (Yazlık) ise don tehlikesi geçtikten sonra Şubat - Mart aylarında.',
        'barley': 'Arpa: Kışlık arpa olarak Ekim ortası - Kasım aylarında ekimi tavsiye edilir.',
        'olive': 'Zeytin: Fidan dikimi genelde don tehlikesi geçtikten sonra Şubat - Mart (kurak bölgelerde sonbaharda) yapılır.',
        'fig': 'İncir: Uykuda olduğu kış sonu (Şubat-Mart) dikim için idealdir.',
        'citrus': 'Narenciye: İlkbaharda don riski bitince (Mart-Nisan) dikimi daha emniyetlidir.',
        'mango': 'Mango: Sıcacık ve ilkbahar yağış başlangıcı / tropikal mevsim dönümleri.',
        'chickpea': 'Nohut: İlkbaharda (Mart sonu-Nisan) toprak ısındıktan sonra ekilir.',
        'lentil': 'Mercimek: Kışlık mercimek için Ekim, yazlık için Şubat-Mart uygundur.',
        'grape': 'Üzüm/Bağ: Fidan (çelik) dikimi kış dinlenmesinde, Şubat ya da Mart ayında yapılmalıdır.',
        'cotton': 'Pamuk: Toprak sıcaklığı 15 derece civarındayken, Nisan ortasından Mayıs başına kadar ekilir.'
    }
    return calendar.get(crop_name, "Genellikle ilkbaharda, don tehlikesi geçtikten sonra ekimi tavsiye edilir.")

@app.post("/recommend_by_location")
def recommend_by_location(data: LocationRequest):
    if not recommender:
        raise HTTPException(status_code=503, detail="Model is not loaded")
    try:
        features = get_soil_and_climate_data(data.lat, data.lng)
        
        result = recommender.predict(
            N=features["N"], P=features["P"], K=features["K"], ph=features["ph"],
            temp_summer=features["temp_summer"], temp_winter=features["temp_winter"],
            rain_summer=features["rain_summer"], rain_winter=features["rain_winter"],
            altitude=features["altitude"]
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
    try:
        soil_map = {name.lower(): name for name in SOIL_DATABASE.keys()}
        soil_key = soil_map.get(data.soil_type.lower())
        if not soil_key:
            raise HTTPException(status_code=400, detail=f"Unsupported soil_type: {data.soil_type}")

        mode = data.mode.capitalize()
        if mode not in {"Hybrid", "Strict"}:
            raise HTTPException(status_code=400, detail="mode must be 'Hybrid' or 'Strict'")

        orchestrator = DataOrchestrator(lat=data.lat, lon=data.lng)
        weather_data = orchestrator.fetch_weather_package()
        weather_source = "open-meteo"
        if not weather_data:
            weather_data = orchestrator.fetch_nasa_fallback()
            weather_source = "nasa-power"

        if not weather_data:
            raise HTTPException(status_code=503, detail="Could not fetch weather data from providers")

        engine = IrrigationEngine(crop_kc=data.crop_kc, soil_type=soil_key)
        result = engine.run_fao56_logic(weather_data, mode=mode, verbose=False)
        result["weather_source"] = weather_source

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
