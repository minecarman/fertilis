"""
Real-World Data Collector for Crop Recommendation
==================================================
Fetches ACTUAL climate and soil data from NASA POWER, ISRIC SoilGrids,
and Open Elevation for known agricultural regions worldwide.

Each location is labeled with the crop that is ACTUALLY grown there
(based on FAO crop maps and agricultural records).

APIs used (all free, no key required):
  - NASA POWER: temperature, humidity, rainfall (20-year climatology)
  - ISRIC SoilGrids: soil pH
  - Open Elevation: altitude

Usage:
    python collect_real_data.py

Output:
    data/real_world_crop_data.csv
"""

import json
import time
import requests
import pandas as pd
import numpy as np
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
DATA_DIR = PROJECT_ROOT / "data"
OUTPUT_FILE = DATA_DIR / "real_world_crop_data.csv"

# ─── Real agricultural locations for each crop ────────────────────────────────
# Each entry: (latitude, longitude, region_name)
# These are actual farming regions sourced from FAO crop distribution maps.

CROP_LOCATIONS = {
    "olive": [
        (37.05, 36.15, "Hatay, Turkey"),
        (37.78, -3.79, "Jaen, Spain"),
        (40.85, 16.55, "Puglia, Italy"),
        (35.24, 24.47, "Crete, Greece"),
        (36.75, 3.05, "Blida, Algeria"),
        (33.87, 9.55, "Sfax, Tunisia"),
        (31.63, -8.00, "Marrakech, Morocco"),
        (38.73, 20.72, "Lefkada, Greece"),
        (43.30, 5.37, "Marseille, France"),
        (39.57, 2.65, "Mallorca, Spain"),
    ],
    "fig": [
        (37.85, 27.85, "Aydin, Turkey"),
        (38.42, -7.90, "Alentejo, Portugal"),
        (36.80, 10.18, "Tunis, Tunisia"),
        (34.05, -6.85, "Meknes, Morocco"),
        (37.39, -5.98, "Seville, Spain"),
        (36.72, -4.42, "Malaga, Spain"),
        (40.65, 22.90, "Thessaloniki, Greece"),
        (38.12, 13.36, "Palermo, Sicily"),
        (33.51, 36.29, "Damascus, Syria"),
        (32.92, 35.07, "Haifa, Israel"),
    ],
    "almond": [
        (38.99, -1.86, "Murcia, Spain"),
        (36.84, -2.46, "Almeria, Spain"),
        (36.74, 3.08, "Algiers, Algeria"),
        (37.94, -1.13, "Alicante, Spain"),
        (36.90, 30.70, "Antalya, Turkey"),
        (34.69, 36.10, "Homs, Syria"),
        (37.05, -8.00, "Algarve, Portugal"),
        (36.72, 4.05, "Boumerdes, Algeria"),
        (38.35, 21.73, "Patras, Greece"),
        (40.18, 18.17, "Lecce, Italy"),
    ],
    "wheat": [
        (30.50, 76.50, "Punjab, India"),
        (38.50, -99.30, "Kansas, USA"),
        (48.17, 1.82, "Beauce, France"),
        (39.73, 32.57, "Ankara, Turkey"),
        (50.45, 30.52, "Kyiv, Ukraine"),
        (46.00, 25.00, "Transylvania, Romania"),
        (34.30, 44.37, "Baghdad, Iraq"),
        (35.18, -1.89, "Oran, Algeria"),
        (52.52, 13.40, "Brandenburg, Germany"),
        (31.95, 35.93, "Amman, Jordan"),
    ],
    "lentil": [
        (37.00, 35.32, "Adana, Turkey"),
        (30.90, 75.85, "Punjab, India"),
        (50.45, -104.60, "Saskatchewan, Canada"),
        (36.20, 37.15, "Aleppo, Syria"),
        (9.03, 38.75, "Addis Ababa, Ethiopia"),
        (39.92, 32.85, "Ankara, Turkey"),
        (28.61, 77.23, "Delhi, India"),
        (38.72, -9.14, "Lisbon, Portugal"),
        (34.52, 69.17, "Kabul, Afghanistan"),
        (40.41, -3.70, "Madrid, Spain"),
    ],
    "chickpea": [
        (26.85, 75.80, "Rajasthan, India"),
        (37.87, 32.49, "Konya, Turkey"),
        (33.59, 44.02, "Diyala, Iraq"),
        (9.14, 40.49, "Harar, Ethiopia"),
        (36.36, 6.61, "Setif, Algeria"),
        (31.05, 31.38, "Dakahlia, Egypt"),
        (34.01, 71.58, "Peshawar, Pakistan"),
        (23.26, 77.41, "Bhopal, India"),
        (38.35, 43.28, "Van, Turkey"),
        (36.72, 34.72, "Mersin, Turkey"),
    ],
    "rice": [
        (10.82, 106.63, "Mekong Delta, Vietnam"),
        (30.57, 114.30, "Wuhan, China"),
        (31.63, 74.87, "Punjab, Pakistan"),
        (26.45, 80.35, "Lucknow, India"),
        (14.60, 100.60, "Central Thailand"),
        (45.07, 7.69, "Po Valley, Italy"),
        (35.23, 136.90, "Nagoya, Japan"),
        (37.57, 127.00, "Seoul, South Korea"),
        (23.81, 90.41, "Dhaka, Bangladesh"),
        (6.93, 79.85, "Colombo, Sri Lanka"),
    ],
    "banana": [
        (10.00, 76.27, "Kerala, India"),
        (14.67, -17.43, "Dakar, Senegal"),
        (-23.55, -46.63, "Sao Paulo, Brazil"),
        (7.49, 3.90, "Ibadan, Nigeria"),
        (1.29, 36.82, "Central Kenya"),
        (0.31, 32.58, "Kampala, Uganda"),
        (14.63, -90.51, "Guatemala City"),
        (10.49, -66.88, "Caracas, Venezuela"),
        (21.47, -77.92, "Camaguey, Cuba"),
        (8.98, -79.52, "Panama City, Panama"),
    ],
    "sugarcane": [
        (-22.91, -43.17, "Rio de Janeiro, Brazil"),
        (26.85, 81.00, "Uttar Pradesh, India"),
        (30.05, 31.23, "Cairo, Egypt"),
        (-29.86, 31.02, "KwaZulu-Natal, SA"),
        (14.60, -90.52, "Guatemala"),
        (10.50, -61.50, "Trinidad"),
        (23.13, 113.26, "Guangzhou, China"),
        (18.47, -69.90, "Santo Domingo, DR"),
        (21.00, 105.85, "Hanoi, Vietnam"),
        (-17.78, -63.18, "Santa Cruz, Bolivia"),
    ],
    "maize": [
        (41.88, -93.10, "Iowa, USA"),
        (19.43, -99.13, "Mexico City Region"),
        (-26.20, 28.04, "Johannesburg, SA"),
        (45.47, -73.60, "Quebec, Canada"),
        (46.07, 14.51, "Ljubljana, Slovenia"),
        (30.04, 31.24, "Nile Delta, Egypt"),
        (23.55, -46.63, "Sao Paulo, Brazil"),
        (7.38, 3.93, "Ibadan, Nigeria"),
        (39.47, -0.38, "Valencia, Spain"),
        (45.27, 19.83, "Vojvodina, Serbia"),
    ],
    "cotton": [
        (33.45, -112.07, "Arizona, USA"),
        (37.75, 38.27, "Sanliurfa, Turkey"),
        (25.20, 71.84, "Rajasthan, India"),
        (39.47, 59.60, "Turkmenistan"),
        (15.50, 32.56, "Khartoum, Sudan"),
        (30.58, 31.50, "Nile Delta, Egypt"),
        (38.56, 68.77, "Dushanbe, Tajikistan"),
        (40.41, 71.78, "Fergana, Uzbekistan"),
        (22.57, 88.36, "Kolkata, India"),
        (31.55, 74.35, "Lahore, Pakistan"),
    ],
    "tomato": [
        (40.85, 14.27, "Naples, Italy"),
        (36.72, -4.42, "Malaga, Spain"),
        (36.82, 10.17, "Tunis, Tunisia"),
        (30.04, 31.24, "Cairo, Egypt"),
        (25.27, -107.20, "Sinaloa, Mexico"),
        (38.72, -9.14, "Lisbon, Portugal"),
        (36.90, 30.70, "Antalya, Turkey"),
        (43.77, 11.25, "Florence, Italy"),
        (33.94, -6.87, "Meknes, Morocco"),
        (37.39, -5.99, "Seville, Spain"),
    ],
    "grape": [
        (45.44, 12.32, "Venice, Italy"),
        (44.84, -0.58, "Bordeaux, France"),
        (41.39, 2.16, "Barcelona, Spain"),
        (38.42, 21.73, "Patras, Greece"),
        (-33.92, 18.42, "Cape Town, SA"),
        (-34.60, -58.38, "Buenos Aires, Argentina"),
        (38.71, -9.14, "Lisbon, Portugal"),
        (47.06, 15.44, "Graz, Austria"),
        (46.20, 6.14, "Geneva, Switzerland"),
        (40.69, 29.94, "Bursa, Turkey"),
    ],
    "citrus": [
        (37.99, -1.13, "Murcia, Spain"),
        (36.90, 30.70, "Antalya, Turkey"),
        (30.04, 31.24, "Cairo, Egypt"),
        (27.50, -99.50, "Texas, USA"),
        (28.61, 77.21, "Delhi, India"),
        (33.89, 35.50, "Beirut, Lebanon"),
        (-23.55, -46.63, "Sao Paulo, Brazil"),
        (37.51, 15.09, "Catania, Sicily"),
        (33.87, -5.55, "Fez, Morocco"),
        (31.77, 35.21, "Jerusalem, Israel"),
    ],
    "mango": [
        (26.85, 80.91, "Lucknow, India"),
        (23.73, 90.40, "Rajshahi, Bangladesh"),
        (14.60, 121.00, "Manila, Philippines"),
        (19.43, -99.13, "Mexico City Region"),
        (6.52, 3.38, "Lagos, Nigeria"),
        (7.49, 3.90, "Ibadan, Nigeria"),
        (15.36, 44.21, "Sana'a, Yemen"),
        (25.29, 51.53, "Doha, Qatar"),
        (16.87, 96.20, "Yangon, Myanmar"),
        (13.08, 80.27, "Chennai, India"),
    ],
}


def fetch_nasa_power(lat, lon):
    """Fetch 20-year climate averages from NASA POWER."""
    url = (
        f"https://power.larc.nasa.gov/api/temporal/climatology/point?"
        f"parameters=T2M,RH2M,PRECTOTCORR&community=AG"
        f"&longitude={lon}&latitude={lat}&format=JSON&start=2001&end=2020"
    )
    try:
        resp = requests.get(url, timeout=30)
        data = resp.json()
        params = data["properties"]["parameter"]
        temp = params["T2M"]["ANN"]
        humidity = params["RH2M"]["ANN"]
        # Rainfall is mm/day, convert to mm/year
        rain_per_day = params["PRECTOTCORR"]["ANN"]
        rainfall = rain_per_day * 365

        # Estimate growing season (months where temp > 5°C)
        monthly_temps = [params["T2M"][m] for m in
                         ["JAN","FEB","MAR","APR","MAY","JUN",
                          "JUL","AUG","SEP","OCT","NOV","DEC"]]
        growing_months = sum(1 for t in monthly_temps if t > 5)
        season_length = growing_months * 30

        return {
            "temperature": round(temp, 2),
            "humidity": round(humidity, 2),
            "rainfall": round(rainfall, 1),
            "season_length": season_length,
        }
    except Exception as e:
        print(f"    NASA POWER failed for ({lat}, {lon}): {e}")
        return None


def fetch_isric_ph(lat, lon):
    """Fetch soil pH from ISRIC SoilGrids."""
    url = (
        f"https://rest.isric.org/soilgrids/v2.0/properties/query?"
        f"lon={lon}&lat={lat}&property=phh2o&depth=0-5cm&value=mean"
    )
    try:
        resp = requests.get(url, timeout=30)
        data = resp.json()
        ph_raw = data["properties"]["layers"][0]["depths"][0]["values"]["mean"]
        if ph_raw is None:
            return None
        return round(ph_raw / 10, 2)  # SoilGrids returns pH * 10
    except Exception as e:
        print(f"    ISRIC failed for ({lat}, {lon}): {e}")
        return None


def fetch_elevation(lat, lon):
    """Fetch altitude from Open Elevation API."""
    url = f"https://api.open-elevation.com/api/v1/lookup?locations={lat},{lon}"
    try:
        resp = requests.get(url, timeout=30)
        data = resp.json()
        return data["results"][0]["elevation"]
    except Exception as e:
        print(f"    Elevation failed for ({lat}, {lon}): {e}")
        return None


def main():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("=" * 60)
    print("  REAL-WORLD AGRICULTURAL DATA COLLECTOR")
    print("=" * 60)
    print(f"  Crops: {len(CROP_LOCATIONS)}")
    total_locations = sum(len(v) for v in CROP_LOCATIONS.values())
    print(f"  Locations: {total_locations}")
    print(f"  APIs: NASA POWER, ISRIC SoilGrids, Open Elevation")
    print("=" * 60)

    all_rows = []
    failed = 0

    for crop, locations in CROP_LOCATIONS.items():
        print(f"\n  [{crop.upper()}] Fetching data for {len(locations)} locations...")

        for lat, lon, name in locations:
            print(f"    -> {name} ({lat}, {lon})...", end=" ")

            # 1. NASA POWER (climate)
            climate = fetch_nasa_power(lat, lon)
            if climate is None:
                failed += 1
                print("SKIP (NASA fail)")
                continue

            # 2. ISRIC SoilGrids (pH)
            ph = fetch_isric_ph(lat, lon)

            # 3. Open Elevation (altitude)
            altitude = fetch_elevation(lat, lon)

            row = {
                "crop": crop,
                "region": name,
                "latitude": lat,
                "longitude": lon,
                "temperature": climate["temperature"],
                "humidity": climate["humidity"],
                "rainfall": climate["rainfall"],
                "season_length": climate["season_length"],
                "ph": ph if ph else np.nan,
                "altitude": altitude if altitude else np.nan,
                # NPK not available from APIs — will be NaN
                "N": np.nan,
                "P": np.nan,
                "K": np.nan,
            }
            all_rows.append(row)
            print(f"OK (T={climate['temperature']}C, Rain={climate['rainfall']}mm)")

            time.sleep(0.5)  # Be polite to the APIs

    df = pd.DataFrame(all_rows)

    # Reorder columns
    cols = ["crop", "region", "latitude", "longitude",
            "N", "P", "K", "temperature", "humidity", "ph",
            "rainfall", "season_length", "altitude"]
    df = df[cols]

    df.to_csv(OUTPUT_FILE, index=False)

    print(f"\n{'=' * 60}")
    print(f"  COLLECTION COMPLETE")
    print(f"{'=' * 60}")
    print(f"  Successful: {len(all_rows)} locations")
    print(f"  Failed: {failed} locations")
    print(f"  Saved to: {OUTPUT_FILE}")
    print(f"\n  NOTE: N, P, K columns are empty (not available from APIs).")
    print(f"  pH and altitude may have some missing values.")
    print(f"  This data can be used for validation / enrichment.")
    print(f"{'=' * 60}")


if __name__ == "__main__":
    main()
