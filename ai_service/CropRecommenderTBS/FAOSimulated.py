"""
FAO-Inspired Agronomic Dataset Generator — v3
===============================================
Generates a realistic agricultural dataset for global + Mediterranean crops.

Design philosophy:
  - Crops are organized into CONFUSION CLUSTERS — groups of 2-3 crops that
    share very similar growing conditions (like real agriculture).
  - Within a cluster, crops differ only on 1-2 key dimensions.
  - Between clusters, crops differ more clearly.
  - Target model accuracy: ~80-87%

Generates ~15,000 samples across 15 crops.
"""

import pandas as pd
import numpy as np
from pathlib import Path

PROJECT_ROOT = Path(__file__).resolve().parent
DATA_DIR = PROJECT_ROOT / "data"
DATA_FILE = DATA_DIR / "master_crop_dataset.csv"

# ─── Crop profiles ────────────────────────────────────────────────────────────
#
# CONFUSION CLUSTERS (crops that are hard to tell apart):
#   Cluster A: olive / fig / almond      — Mediterranean dryland, similar NPK
#   Cluster B: wheat / lentil / chickpea — cool-season, legume-like overlap
#   Cluster C: rice / banana / sugarcane — tropical wetland, high rainfall
#   Cluster D: maize / cotton / tomato   — warm-season row crops, high N
#   Cluster E: grape / citrus / mango    — fruit trees, moderate conditions
#
# Within each cluster, profiles are deliberately CLOSE on most axes.

CROP_PROFILES = {
    # ── Cluster A: Mediterranean Dryland ──────────────────────────────────
    "olive": {
        "N": 35,  "P": 18, "K": 55,
        "temp": 19, "hum": 52, "ph": 7.6, "rain": 480,
        "season": 230, "altitude": 380
    },
    "fig": {
        "N": 30,  "P": 15, "K": 50,       # very close to olive
        "temp": 21, "hum": 48, "ph": 7.3, "rain": 420,
        "season": 210, "altitude": 420     # slightly higher, shorter season
    },
    "almond": {
        "N": 40,  "P": 22, "K": 60,       # close to olive
        "temp": 17, "hum": 42, "ph": 7.4, "rain": 380,
        "season": 220, "altitude": 500     # higher altitude distinguishes
    },

    # ── Cluster B: Cool-season / Legumes ──────────────────────────────────
    "wheat": {
        "N": 75,  "P": 42, "K": 48,
        "temp": 15, "hum": 52, "ph": 6.8, "rain": 520,
        "season": 135, "altitude": 400
    },
    "lentil": {
        "N": 22,  "P": 48, "K": 55,       # lower N (legume), close P/K
        "temp": 14, "hum": 48, "ph": 7.0, "rain": 380,
        "season": 110, "altitude": 500     # slightly higher
    },
    "chickpea": {
        "N": 25,  "P": 55, "K": 52,       # legume-like low N, high P
        "temp": 18, "hum": 40, "ph": 7.3, "rain": 420,
        "season": 120, "altitude": 550
    },

    # ── Cluster C: Tropical Wetland ───────────────────────────────────────
    "rice": {
        "N": 105, "P": 48, "K": 55,
        "temp": 27, "hum": 84, "ph": 5.9, "rain": 1450,
        "season": 140, "altitude": 25
    },
    "banana": {
        "N": 100, "P": 72, "K": 200,      # stands out on K
        "temp": 28, "hum": 82, "ph": 5.8, "rain": 1600,  # close to rice
        "season": 290, "altitude": 45
    },
    "sugarcane": {
        "N": 140, "P": 55, "K": 120,
        "temp": 30, "hum": 80, "ph": 6.2, "rain": 1550,  # close to rice
        "season": 330, "altitude": 35      # season distinguishes
    },

    # ── Cluster D: Warm-season Row Crops ──────────────────────────────────
    "maize": {
        "N": 115, "P": 48, "K": 72,
        "temp": 25, "hum": 62, "ph": 6.2, "rain": 780,
        "season": 135, "altitude": 150
    },
    "cotton": {
        "N": 120, "P": 58, "K": 85,       # close to maize
        "temp": 28, "hum": 55, "ph": 6.5, "rain": 680,
        "season": 175, "altitude": 100
    },
    "tomato": {
        "N": 125, "P": 52, "K": 155,      # K is distinctly high
        "temp": 24, "hum": 65, "ph": 6.0, "rain": 700,
        "season": 125, "altitude": 60
    },

    # ── Cluster E: Fruit Trees ────────────────────────────────────────────
    "grape": {
        "N": 55,  "P": 32, "K": 110,
        "temp": 16, "hum": 58, "ph": 6.4, "rain": 620,
        "season": 185, "altitude": 280
    },
    "citrus": {
        "N": 85,  "P": 38, "K": 85,       # higher N than grape
        "temp": 22, "hum": 68, "ph": 6.5, "rain": 850,
        "season": 290, "altitude": 110
    },
    "mango": {
        "N": 70,  "P": 42, "K": 100,      # between grape and citrus
        "temp": 30, "hum": 52, "ph": 5.6, "rain": 950,
        "season": 155, "altitude": 200
    },
}

# ─── Standard deviations ─────────────────────────────────────────────────────
# Calibrated so within-cluster crops overlap substantially on most axes,
# but the *combination* of all 9 features still allows ~80-85% accuracy.
STDS = {
    "N":        15,
    "P":        10,
    "K":        22,
    "temp":     3.0,
    "hum":      8,
    "ph":       0.5,
    "rain":     120,
    "season":   30,
    "altitude": 100,
}

SAMPLES_PER_CROP = 1000


def generate_data():
    DATA_DIR.mkdir(parents=True, exist_ok=True)

    print("Generating realistic FAO/ISRIC agronomic dataset (v3)...")
    np.random.seed(42)

    all_rows = []

    for crop, profile in CROP_PROFILES.items():
        n = SAMPLES_PER_CROP
        vals = {
            "N":             np.random.normal(profile["N"],        STDS["N"],        n),
            "P":             np.random.normal(profile["P"],        STDS["P"],        n),
            "K":             np.random.normal(profile["K"],        STDS["K"],        n),
            "temperature":   np.random.normal(profile["temp"],     STDS["temp"],     n),
            "humidity":      np.random.normal(profile["hum"],      STDS["hum"],      n),
            "ph":            np.random.normal(profile["ph"],       STDS["ph"],       n),
            "rainfall":      np.random.normal(profile["rain"],     STDS["rain"],     n),
            "season_length": np.random.normal(profile["season"],   STDS["season"],   n),
            "altitude":      np.random.normal(profile["altitude"], STDS["altitude"], n),
        }

        # Physical constraints
        vals["N"]             = np.clip(vals["N"],             0, 300)
        vals["P"]             = np.clip(vals["P"],             0, 200)
        vals["K"]             = np.clip(vals["K"],             0, 400)
        vals["temperature"]   = np.clip(vals["temperature"],   -5, 50)
        vals["humidity"]      = np.clip(vals["humidity"],       5, 100)
        vals["ph"]            = np.clip(vals["ph"],            3.5, 9.5)
        vals["rainfall"]      = np.clip(vals["rainfall"],      20, 4000)
        vals["season_length"] = np.clip(vals["season_length"], 30, 365)
        vals["altitude"]      = np.clip(vals["altitude"],      0, 3000)

        for i in range(n):
            row = {feat: round(vals[feat][i], 2) for feat in vals}
            row["label"] = crop
            all_rows.append(row)

    df = pd.DataFrame(all_rows)
    df = df.sample(frac=1, random_state=42).reset_index(drop=True)
    df.to_csv(DATA_FILE, index=False)

    print(f"  Generated {len(df)} samples across {len(CROP_PROFILES)} crops.")
    print(f"  Columns: {list(df.columns)}")
    print(f"  Saved to {DATA_FILE}")

    # Print cluster overlap preview
    print("\n  Confusion Clusters (intentionally close):")
    print("    A: olive / fig / almond          (dryland Med.)")
    print("    B: wheat / lentil / chickpea      (cool legumes)")
    print("    C: rice / banana / sugarcane      (tropical wet)")
    print("    D: maize / cotton / tomato        (warm row crops)")
    print("    E: grape / citrus / mango         (fruit trees)")


if __name__ == "__main__":
    generate_data()
