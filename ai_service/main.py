import requests
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import sys
import os
from pathlib import Path

# Add CropRecommenderTBS to path so we can import from it easily
from CropRecommenderTBS.predict import CropRecommender
# from IrrigatorV2.1 import DataOrchestrator # You can import your irrigator logic similarly

app = FastAPI(title="Fertilis AI Microservice")

# Assuming predict.py exposes CropRecommender
# Initialize model on startup
try:
    model_path = Path(__file__).parent / "CropRecommenderTBS" / "models" / "crop_model.pkl"
    recommender = CropRecommender(str(model_path))
except Exception as e:
    recommender = None
    print(f"Warning: Could not load the crop recommendation model: {e}")

class CropRequest(BaseModel):
    N: float
    P: float
    K: float
    temperature: float
    humidity: float
    ph: float
    rainfall: float
    season_length: float
    altitude: float

@app.post("/predict_crop")
def predict_crop(data: CropRequest):
    if not recommender:
        raise HTTPException(status_code=503, detail="Model is not loaded")
    
    try:
        result = recommender.predict(
            N=data.N, P=data.P, K=data.K, 
            temperature=data.temperature, humidity=data.humidity,
            ph=data.ph, rainfall=data.rainfall, 
            season_length=data.season_length, altitude=data.altitude
        )
        return {"recommendation": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/health")
def health_check():
    return {"status": "healthy"}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
