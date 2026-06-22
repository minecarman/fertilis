import requests
import pandas as pd
import random
import time
import os

# Define approximate bounding boxes for crops (min_lat, max_lat, min_lng, max_lng)
CROP_REGIONS = {
    'apple': [(40.0, 48.0, -122.0, -117.0)], # Washington State, USA
    'banana': [(10.0, 15.0, 100.0, 105.0)], # Southeast Asia
    'blackgram': [(20.0, 25.0, 75.0, 80.0)], # Central India
    'chickpea': [(25.0, 30.0, 70.0, 75.0)], # Northern India
    'coconut': [(8.0, 12.0, 75.0, 80.0)], # Southern India / Sri Lanka
    'coffee': [(-20.0, -10.0, -50.0, -40.0)], # Brazil
    'cotton': [(30.0, 35.0, -100.0, -90.0)], # Texas, USA
    'grapes': [(40.0, 45.0, 5.0, 15.0)], # Italy / France
    'jute': [(22.0, 25.0, 88.0, 90.0)], # West Bengal / Bangladesh
    'kidneybeans': [(35.0, 45.0, -110.0, -100.0)], # Northern USA
    'lentil': [(50.0, 55.0, -110.0, -100.0)], # Saskatchewan, Canada
    'maize': [(40.0, 45.0, -95.0, -85.0)], # US Corn Belt
    'mango': [(15.0, 20.0, 75.0, 80.0)], # Western India
    'mothbeans': [(25.0, 28.0, 70.0, 75.0)], # Rajasthan, India
    'mungbean': [(15.0, 20.0, 100.0, 105.0)], # Thailand
    'muskmelon': [(35.0, 40.0, -120.0, -115.0)], # California, USA
    'orange': [(25.0, 30.0, -85.0, -80.0)], # Florida, USA
    'papaya': [(15.0, 20.0, -100.0, -95.0)], # Mexico
    'pigeonpeas': [(15.0, 20.0, 75.0, 80.0)], # India
    'pomegranate': [(30.0, 35.0, 50.0, 55.0)], # Iran
    'rice': [(10.0, 20.0, 100.0, 105.0)], # Vietnam / Thailand
    'watermelon': [(30.0, 35.0, -90.0, -85.0)] # Southern USA
}

def fetch_soil_data(lat, lng):
    url = "https://rest.isric.org/soilgrids/v2.0/properties/query"
    params = {
        'lat': lat, 'lon': lng,
        'property': ['phh2o', 'nitrogen', 'soc'],
        'depth': '0-5cm', 'value': 'mean'
    }
    try:
        res = requests.get(url, params=params, timeout=10)
        if res.status_code == 200:
            data = res.json()
            results = {}
            for layer in data.get('properties', {}).get('layers', []):
                name = layer.get('name')
                depths = layer.get('depths', [])
                if depths:
                    val = depths[0].get('values', {}).get('mean')
                    results[name] = val
            
            # Conversions based on your service logic
            ph = (results.get('phh2o', 65) / 10.0) if results.get('phh2o') else 6.5
            n = (results.get('nitrogen', 480) / 8.0) if results.get('nitrogen') else 60.0
            soc = results.get('soc', 800)
            p = (soc / 20.0) if soc else 40.0
            k = (soc / 12.0) if soc else 50.0
            
            return n, p, k, ph
    except:
        pass
    return None, None, None, None

def fetch_climate_data(lat, lng):
    url = f"https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=T2M,PRECTOTCORR,RH2M&community=ag&longitude={lng}&latitude={lat}&format=JSON"
    try:
        res = requests.get(url, timeout=10)
        if res.status_code == 200:
            data = res.json().get('properties', {}).get('parameter', {})
            t2m = data.get('T2M', {})
            prect = data.get('PRECTOTCORR', {})
            rh2m = data.get('RH2M', {})
            
            temp = sum(t2m.values()) / len(t2m) if t2m else 25.0
            humidity = sum(rh2m.values()) / len(rh2m) if rh2m else 70.0
            rainfall = (sum(prect.values()) / len(prect)) * 30.5 if prect else 150.0
            return temp, humidity, rainfall
    except:
        pass
    return None, None, None

def main():
    print("Mining real world data from APIs...")
    results = []
    
    # 5 samples per crop
    for crop, boxes in CROP_REGIONS.items():
        print(f"Mining data for {crop}...")
        for _ in range(5):
            box = random.choice(boxes)
            lat = random.uniform(box[0], box[1])
            lng = random.uniform(box[2], box[3])
            
            n, p, k, ph = fetch_soil_data(lat, lng)
            temp, humidity, rainfall = fetch_climate_data(lat, lng)
            
            if n is not None and temp is not None:
                results.append({
                    "N": n, "P": p, "K": k, 
                    "temperature": temp, "humidity": humidity, 
                    "ph": ph, "rainfall": rainfall, "label": crop
                })
            time.sleep(0.5) # respect rate limits
            
    df = pd.DataFrame(results)
    df.to_csv('c:/Users/muham/Downloads/fertilis-main/fertilis-main/ml_services/crop_recommendation/data/real_world_additional_crops.csv', index=False)
    print(f"Mined {len(df)} real-world samples. Saved to data/real_world_additional_crops.csv")

if __name__ == "__main__":
    main()
