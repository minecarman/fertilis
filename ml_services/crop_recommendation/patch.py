import requests

def patch_file():
    with open("soilgrids_service.py", "r", encoding="utf-8") as f:
        content = f.read()

    new_function = """def fetch_climate_data_nasa(lat, lng):
    try:
        url = f"https://power.larc.nasa.gov/api/temporal/climatology/point?parameters=T2M,RH2M,PRECTOTCORR&community=ag&longitude={lng}&latitude={lat}&format=JSON"
        import requests
        res = requests.get(url, timeout=15)
        res.raise_for_status()
        data = res.json().get('properties', {}).get('parameter', {})
        
        # T2M: Temperature at 2 Meters (Annual Average)
        temp_annual = data.get('T2M', {}).get('ANN', 16.0)
        
        # RH2M: Relative Humidity at 2 Meters (Annual Average)
        humidity = data.get('RH2M', {}).get('ANN', 40.0)
        
        # PRECTOTCORR: Precipitation Corrected (mm/day) -> Convert to annual total (mm/year)
        daily_rain_avg = data.get('PRECTOTCORR', {}).get('ANN', 1.0)
        annual_rainfall = daily_rain_avg * 365.0
        
        return float(temp_annual), float(humidity), float(annual_rainfall)
    except Exception as e:
        print(f"NASA POWER API Hatasi: {e}")
        return 16.0, 40.0, 400.0

def get_soil_and_climate_data(lat, lng):
    print(f"??? {lat}, {lng} icin gercek Agroklimatoloji verileri NASA POWER API üzerinden sorgulaniyor...")
    temp_annual, humidity, annual_rainfall = fetch_climate_data_nasa(lat, lng)
"""
    
    parts = content.split("def get_soil_and_climate_data(lat, lng):", 1)
    top_part = parts[0]
    bottom_part = parts[1]
    keep_part = bottom_part.split("soil_data = fetch_soil_data_rest(lat, lng)", 1)[1]
    
    final_content = top_part + new_function + "\n    soil_data = fetch_soil_data_rest(lat, lng)" + keep_part
    
    with open("soilgrids_service.py", "w", encoding="utf-8") as f:
        f.write(final_content)

patch_file()
