"""Quick test of prediction module v2."""
from predict_crop import CropRecommender
import json

recommender = CropRecommender()

# Test 1: Olive (Mediterranean — dry, high altitude, long season)
print("=" * 55)
print("Test 1: Olive conditions (Mediterranean)")
print("=" * 55)
result = recommender.predict(
    N=30, P=15, K=50,
    temperature=18.0, humidity=55.0, ph=7.8, rainfall=500.0,
    season_length=240, altitude=350
)
print(json.dumps(result, indent=2))

# Test 2: Rice (Tropical India — hot, wet, low altitude)
print("\n" + "=" * 55)
print("Test 2: Rice conditions (Tropical)")
print("=" * 55)
result2 = recommender.predict(
    N=110, P=50, K=55,
    temperature=28.0, humidity=85.0, ph=5.8, rainfall=1500.0,
    season_length=140, altitude=20
)
print(json.dumps(result2, indent=2))

# Test 3: Wheat (Temperate — cool, moderate rain)
print("\n" + "=" * 55)
print("Test 3: Wheat conditions (Temperate)")
print("=" * 55)
result3 = recommender.predict(
    N=80, P=45, K=45,
    temperature=14.0, humidity=50.0, ph=6.8, rainfall=550.0,
    season_length=130, altitude=400
)
print(json.dumps(result3, indent=2))

# Test 4: Crop info API
print("\n" + "=" * 55)
print("Test 4: Crop info")
print("=" * 55)
info = recommender.get_crop_info()
print(f"Supported crops ({info['num_crops']}): {info['supported_crops']}")
