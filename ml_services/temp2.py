import joblib
import pandas as pd
import numpy as np

class CropRecommender:
    def __init__(self, model_path):
        package = joblib.load(model_path)
        self.model = package['model']
        self.scaler = package['scaler']
        self.label_encoder = package['label_encoder']

    def predict(self, N, P, K, ph, temp_summer, temp_winter, rain_summer, rain_winter, altitude):
        df = pd.DataFrame([{
            "N": N, "P": P, "K": K, "ph": ph, 
            "temp_summer": temp_summer, "temp_winter": temp_winter,
            "rain_summer": rain_summer, "rain_winter": rain_winter,
            "altitude": altitude
        }])
        
        df_scaled = self.scaler.transform(df)
        proba = self.model.predict_proba(df_scaled)[0]
        
        results = [{"crop": crop, "confidence": float(prob)} for crop, prob in zip(self.label_encoder.classes_, proba)]
        results = sorted(results, key=lambda x: x["confidence"], reverse=True)
        return results[:10]
