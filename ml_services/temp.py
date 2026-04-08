import joblib
import pandas as pd

class CropRecommender:
    def __init__(self, model_path):
        self.model = joblib.load(model_path)
        self.classes = self.model.classes_

    def predict(self, N, P, K, ph, temp_summer, temp_winter, rain_summer, rain_winter, altitude):
        df = pd.DataFrame([{
            "N": N, "P": P, "K": K, "ph": ph, 
            "temp_summer": temp_summer, "temp_winter": temp_winter,
            "rain_summer": rain_summer, "rain_winter": rain_winter,
            "altitude": altitude
        }])
        
        proba = self.model.predict_proba(df)[0]
        
        results = [{"crop": crop, "confidence": float(prob)} for crop, prob in zip(self.classes, proba)]
        results = sorted(results, key=lambda x: x["confidence"], reverse=True)
        return results[:10]
