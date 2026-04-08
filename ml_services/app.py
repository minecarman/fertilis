from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from pathlib import Path
from typing import Optional
from crop_recommendation.predict_crop import CropRecommender
from crop_recommendation.soilgrids_service import get_soil_and_climate_data

app = FastAPI(title="Fertilis AI Microservice")

try:
    model_path = Path(__file__).parent / "crop_recommendation" / "models" / "crop_model.pkl"
    recommender = CropRecommender(str(model_path))
except Exception as e:
    recommender = None
    print(f"Warning: Could not load the crop recommendation model: {e}")

class LocationRequest(BaseModel):
    lat: float
    lng: float

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

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
