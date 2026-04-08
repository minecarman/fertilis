import re

# Update train_model.py
with open("train_model.py", "r", encoding="utf-8") as f:
    text = f.read()

text = text.replace("master_crop_dataset.csv", "seasonal_crop_dataset.csv")

# Regular expression to replace the FEATURES list (across multiple lines if needed)
pattern = r"features\s*=\s*\[\s*(['\"].*?['\"]\s*,\s*)*['\"].*?['\"]\s*\]"
new_features = "features = ['N', 'P', 'K', 'ph', 'temp_summer', 'temp_winter', 'rain_summer', 'rain_winter', 'altitude']"
text = re.sub(pattern, new_features, text, flags=re.DOTALL)

with open("train_model.py", "w", encoding="utf-8") as f:
    f.write(text)


# Update predict_crop.py
with open("predict_crop.py", "r", encoding="utf-8") as f:
    text = f.read()

pattern2 = r"ORIGINAL_FEATURES\s*=\s*\[\s*(['\"].*?['\"]\s*,\s*)*['\"].*?['\"]\s*\]"
new_original = "ORIGINAL_FEATURES = ['N', 'P', 'K', 'ph', 'temp_summer', 'temp_winter', 'rain_summer', 'rain_winter', 'altitude']"
text = re.sub(pattern2, new_original, text, flags=re.DOTALL)

# Adjust predict signature
old_sig = "def predict(self, N:float, P:float, K:float, temperature:float, humidity:float, ph:float, rainfall:float, season_length:float, altitude:float):"
new_sig = "def predict(self, N:float, P:float, K:float, ph:float, temp_summer:float, temp_winter:float, rain_summer:float, rain_winter:float, altitude:float):"
text = text.replace(old_sig, new_sig)

# Adjust list inside predict
text = text.replace("N, P, K, temperature, humidity, ph, rainfall, season_length, altitude", 
                    "N, P, K, ph, temp_summer, temp_winter, rain_summer, rain_winter, altitude")

# Adjust df columns inside predict
text = text.replace('columns=["N", "P", "K", "temperature", "humidity", "ph", "rainfall", "season_length", "altitude"]',
                    'columns=["N", "P", "K", "ph", "temp_summer", "temp_winter", "rain_summer", "rain_winter", "altitude"]')

with open("predict_crop.py", "w", encoding="utf-8") as f:
    f.write(text)

print("Updated train_model.py and predict_crop.py")
