import requests
import os
import math

def fetch_soil_data_rest(lat, lng):
    try:
        url = "https://rest.isric.org/soilgrids/v2.0/properties/query"
        params = {
            'lat': lat,
            'lon': lng,
            'property': ['phh2o', 'nitrogen', 'soc'],
            'depth': '0-5cm',
            'value': 'mean'
        }
        res = requests.get(url, params=params, timeout=15)
        res.raise_for_status()
        data = res.json()
        
        results = {'phh2o': None, 'nitrogen': None, 'soc': None}
        layers = data.get('properties', {}).get('layers', [])
        for layer in layers:
            name = layer.get('name')
            if name in results:
                depths = layer.get('depths', [])
                if depths:
                    values = depths[0].get('values', {})
                    if values:
                        results[name] = values.get('mean')
        return results
    except Exception as e:
        print(f"REST API SoilGrids Hatasi: {e}")
        return {'phh2o': None, 'nitrogen': None, 'soc': None}

def fetch_climate_data_nasa(lat, lng):
    try:
        url = f"https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=T2M,PRECTOTCORR,RH2M&community=ag&longitude={lng}&latitude={lat}&format=JSON"
        res = requests.get(url, timeout=12)
        res.raise_for_status()
        
        data = res.json().get('properties', {}).get('parameter', {})
        t2m = data.get('T2M', {})
        prect = data.get('PRECTOTCORR', {})
        rh2m = data.get('RH2M', {})

        # Calculate averages for the year (or growing season approximation)
        temperature = sum(t2m.values()) / len(t2m) if t2m else 25.0
        humidity = sum(rh2m.values()) / len(rh2m) if rh2m else 70.0
        # PRECTOTCORR is mm/day. Average monthly rainfall = average(mm/day) * 30.5
        rainfall = (sum(prect.values()) / len(prect)) * 30.5 if prect else 150.0

        return float(temperature), float(humidity), float(rainfall)
    except Exception as e:
        print(f"NASA POWER API Hatasi (Fallback kullanilacak): {e}")
        return 25.0, 70.0, 150.0

def get_soil_and_climate_data(lat, lng):
    print(f"NASA POWER API: Mevsimsel Iklim (Sicaklik, Nem, Yagis)...")
    temperature, humidity, rainfall = fetch_climate_data_nasa(lat, lng)
    
    print(f"NASA -> Sicaklik: {temperature:.1f}C, Nem: {humidity:.1f}%, Yagis: {rainfall:.1f}mm")

    print(f"SoilGrids REST API: Toprak (pH, N, Karbon)...")
    soil_data = fetch_soil_data_rest(lat, lng)
    
    raw_ph = soil_data.get('phh2o')
    raw_n = soil_data.get('nitrogen')
    raw_soc = soil_data.get('soc')

    ph = (raw_ph / 10.0) if raw_ph is not None else 6.5
    n = (float(raw_n) / 8.0) if raw_n is not None else 60.0
    p = (float(raw_soc) / 20.0) if raw_soc is not None else 40.0
    k = (float(raw_soc) / 12.0) if raw_soc is not None else 50.0

    n = max(20, min(n, 120))
    p = max(15, min(p, 90))
    k = max(20, min(k, 150))

    return {
        "N": float(n),
        "P": float(p),
        "K": float(k),
        "temperature": float(temperature),
        "humidity": float(humidity),
        "ph": float(ph),
        "rainfall": float(rainfall)
    }
