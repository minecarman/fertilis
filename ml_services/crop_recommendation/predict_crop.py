import joblib
import pandas as pd
import numpy as np

class CropRecommender:
    def __init__(self, model_path):
        package = joblib.load(model_path)
        self.model = package['model']
        self.scaler = package['scaler']
        self.label_encoder = package['label_encoder']

    def predict(self, N, P, K, temperature, humidity, ph, rainfall):
        df = pd.DataFrame([{
            "N": N, "P": P, "K": K, 
            "temperature": temperature, "humidity": humidity,
            "ph": ph, "rainfall": rainfall
        }])
        
        df_scaled = self.scaler.transform(df)
        proba = self.model.predict_proba(df_scaled)[0]
        
        results = [{"crop": crop, "confidence": float(prob)} for crop, prob in zip(self.label_encoder.classes_, proba)]
        results = sorted(results, key=lambda x: x["confidence"], reverse=True)
        return results[:10]
