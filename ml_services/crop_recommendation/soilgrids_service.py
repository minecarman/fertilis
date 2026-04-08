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
        url = f"https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=T2M,PRECTOTCORR&community=ag&longitude={lng}&latitude={lat}&format=JSON"
        res = requests.get(url, timeout=12)
        res.raise_for_status()
        
        data = res.json().get('properties', {}).get('parameter', {})
        t2m = data.get('T2M', {})
        prect = data.get('PRECTOTCORR', {})

        temp_summer = (t2m.get('JUN', 28.0) + t2m.get('JUL', 30.0) + t2m.get('AUG', 30.0)) / 3.0
        temp_winter = (t2m.get('DEC', 5.0) + t2m.get('JAN', 3.0) + t2m.get('FEB', 4.0)) / 3.0

        rain_summer = (prect.get('JUN', 0.5) + prect.get('JUL', 0.1) + prect.get('AUG', 0.1)) * 30.5
        rain_winter = (prect.get('DEC', 3.0) + prect.get('JAN', 3.5) + prect.get('FEB', 3.0)) * 30.0

        return float(temp_summer), float(temp_winter), float(rain_summer), float(rain_winter)
    except Exception as e:
        print(f"NASA POWER API Hatasi (Fallback kullanilacak): {e}")
        return 28.0, 5.0, 30.0, 250.0

def fetch_elevation_openmeteo(lat, lng):
    try:
        url = f"https://api.open-meteo.com/v1/elevation?latitude={lat}&longitude={lng}"
        res = requests.get(url, timeout=10)
        res.raise_for_status()
        data = res.json()
        elevation = data.get('elevation', [None])[0]
        if elevation is None:
            return 500.0
        return float(elevation)
    except Exception as e:
        print(f"Open-Meteo elevation error: {e}")
        return 500.0

def get_soil_and_climate_data(lat, lng):
    print(f"NASA POWER API: Mevsimsel Iklim (Sicaklik, Yagis)...")
    temp_summer, temp_winter, rain_summer, rain_winter = fetch_climate_data_nasa(lat, lng)
    
    print(f"NASA -> Yaz Sicakligi: {temp_summer:.1f}C, Kış: {temp_winter:.1f}C, Yaz Yağışı: {rain_summer:.1f}mm, Kış: {rain_winter:.1f}mm")

    print(f"Open-Meteo API: Rakim...")
    altitude = fetch_elevation_openmeteo(lat, lng)

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
        "temp_summer": float(temp_summer),
        "temp_winter": float(temp_winter),
        "rain_summer": float(rain_summer),
        "rain_winter": float(rain_winter),
        "ph": float(ph),
        "altitude": float(altitude)
    }
