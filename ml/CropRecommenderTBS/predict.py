"""
Crop Recommendation — Prediction Module (v2)
=============================================
Updated for realistic FAO dataset with 9 input features.

Backend usage:
    from predict import CropRecommender
    recommender = CropRecommender("models/crop_model.pkl")
    result = recommender.predict(
        N=40, P=15, K=50, temperature=18, humidity=55,
        ph=7.8, rainfall=500, season_length=240, altitude=350
    )

CLI usage:
    python predict.py                    # Interactive mode
    python predict.py --N 40 --P 15 ...  # Single prediction
"""

import json
import argparse
import sys
from pathlib import Path
from typing import Optional

import numpy as np
import pandas as pd
import joblib


class CropRecommender:
    """Production-ready crop recommendation predictor."""

    FEATURE_RANGES = {
        "N":             (0, 300,   "Nitrogen content (kg/ha)"),
        "P":             (0, 200,   "Phosphorus content (kg/ha)"),
        "K":             (0, 400,   "Potassium content (kg/ha)"),
        "temperature":   (-5, 50,   "Average temperature in C"),
        "humidity":      (5, 100,   "Relative humidity in %"),
        "ph":            (3.5, 9.5, "Soil pH value"),
        "rainfall":      (20, 4000, "Annual rainfall in mm"),
        "season_length": (30, 365,  "Growing season length in days"),
        "altitude":      (0, 3000,  "Altitude in meters above sea level"),
    }

    ORIGINAL_FEATURES = ["N", "P", "K", "temperature", "humidity", "ph",
                         "rainfall", "season_length", "altitude"]

    def __init__(self, model_path: Optional[str] = None):
        if model_path is None:
            model_path = Path(__file__).resolve().parent / "models" / "crop_model.pkl"
        else:
            model_path = Path(model_path)

        if not model_path.exists():
            raise FileNotFoundError(f"Model not found at {model_path}. Run train.py first.")

        package = joblib.load(model_path)
        self.model = package["model"]
        self.scaler = package["scaler"]
        self.label_encoder = package["label_encoder"]
        self.feature_names = package["feature_names"]

    def _engineer_features(self, row: dict) -> dict:
        """Apply identical feature engineering as training."""
        r = row.copy()
        r["npk_total"] = r["N"] + r["P"] + r["K"]
        npk_sum = r["npk_total"] + 1e-8
        r["n_ratio"] = r["N"] / npk_sum
        r["p_ratio"] = r["P"] / npk_sum
        r["k_ratio"] = r["K"] / npk_sum
        r["n_to_p"] = r["N"] / (r["P"] + 1e-8)
        r["n_to_k"] = r["N"] / (r["K"] + 1e-8)
        r["humidity_temp"] = r["humidity"] * r["temperature"] / 100
        r["rainfall_per_temp"] = r["rainfall"] / (r["temperature"] + 1e-8)
        r["ph_deviation_from_neutral"] = abs(r["ph"] - 7.0)
        r["rain_per_season"] = r["rainfall"] / (r["season_length"] + 1e-8)
        r["temp_altitude"] = r["temperature"] / (r["altitude"] + 1.0)
        return r

    def validate_input(self, **kwargs) -> list:
        warnings = []
        for feat in self.ORIGINAL_FEATURES:
            if feat not in kwargs:
                warnings.append(f"Missing required feature: {feat}")
                continue
            val = kwargs[feat]
            lo, hi, desc = self.FEATURE_RANGES[feat]
            if not isinstance(val, (int, float)):
                warnings.append(f"{feat}: Expected number, got {type(val).__name__}")
            elif val < lo or val > hi:
                warnings.append(f"{feat}={val} outside range [{lo}, {hi}] ({desc})")
        return warnings

    def predict(self, *, N: float, P: float, K: float, temperature: float,
                humidity: float, ph: float, rainfall: float,
                season_length: float, altitude: float,
                top_k: int = 3, validate: bool = True) -> dict:
        input_dict = {
            "N": float(N), "P": float(P), "K": float(K),
            "temperature": float(temperature), "humidity": float(humidity),
            "ph": float(ph), "rainfall": float(rainfall),
            "season_length": float(season_length), "altitude": float(altitude),
        }

        warnings_list = self.validate_input(**input_dict) if validate else []

        try:
            engineered = self._engineer_features(input_dict)
            feature_vector = np.array(
                [engineered[f] for f in self.feature_names]
            ).reshape(1, -1)
            feature_vector_scaled = self.scaler.transform(feature_vector)

            probabilities = self.model.predict_proba(feature_vector_scaled)[0]
            top_indices = np.argsort(probabilities)[::-1][:top_k]

            recommendations = []
            for idx in top_indices:
                crop_name = self.label_encoder.inverse_transform([idx])[0]
                confidence = float(probabilities[idx])
                recommendations.append({
                    "crop": crop_name,
                    "confidence": round(confidence, 4),
                })

            return {
                "success": True,
                "top_recommendation": recommendations[0]["crop"],
                "confidence": recommendations[0]["confidence"],
                "recommendations": recommendations,
                "warnings": warnings_list,
                "input_summary": input_dict,
            }
        except Exception as e:
            return {
                "success": False,
                "error": str(e),
                "warnings": warnings_list,
                "input_summary": input_dict,
            }

    def predict_batch(self, df: pd.DataFrame, top_k: int = 3) -> pd.DataFrame:
        results = []
        for _, row in df.iterrows():
            result = self.predict(
                N=row["N"], P=row["P"], K=row["K"],
                temperature=row["temperature"], humidity=row["humidity"],
                ph=row["ph"], rainfall=row["rainfall"],
                season_length=row["season_length"], altitude=row["altitude"],
                top_k=top_k, validate=False
            )
            results.append({
                "predicted_crop": result.get("top_recommendation", "error"),
                "confidence": result.get("confidence", 0),
                "top_k_str": ", ".join(
                    f"{r['crop']}({r['confidence']:.2f})"
                    for r in result.get("recommendations", [])
                ),
            })
        return pd.concat([df.reset_index(drop=True), pd.DataFrame(results)], axis=1)

    def get_crop_info(self) -> dict:
        return {
            "supported_crops": list(self.label_encoder.classes_),
            "num_crops": len(self.label_encoder.classes_),
            "required_features": self.ORIGINAL_FEATURES,
        }


#CLI

def interactive_mode(recommender: CropRecommender):
    print("\n" + "=" * 60)
    print("  CROP RECOMMENDER v2 (FAO Data for example)")
    print("=" * 60)
    print("  Type 'q' to quit.\n")

    while True:
        try:
            print("-" * 50)
            n_in = input("  Nitrogen (N) [0-300]: ").strip()
            if n_in.lower() in ("q", "quit", "exit"):
                break

            N = float(n_in)
            P = float(input("  Phosphorus (P) [0-200]: ").strip())
            K = float(input("  Potassium (K) [0-400]: ").strip())
            temp = float(input("  Temperature (C) [-5 to 50]: ").strip())
            hum = float(input("  Humidity (%) [5-100]: ").strip())
            ph = float(input("  pH [3.5-9.5]: ").strip())
            rain = float(input("  Rainfall (mm) [20-4000]: ").strip())
            season = float(input("  Growing season (days) [30-365]: ").strip())
            alt = float(input("  Altitude (m) [0-3000]: ").strip())

            result = recommender.predict(
                N=N, P=P, K=K, temperature=temp, humidity=hum,
                ph=ph, rainfall=rain, season_length=season,
                altitude=alt, top_k=5
            )

            if result["success"]:
                print(f"\n  BEST: {result['top_recommendation'].upper()} "
                      f"({result['confidence']*100:.1f}%)")
                print("  Top 5:")
                for i, r in enumerate(result["recommendations"], 1):
                    bar = "#" * int(r["confidence"] * 40)
                    print(f"    {i}. {r['crop']:<15} {r['confidence']*100:>5.1f}% {bar}")
                if result["warnings"]:
                    print("  Warnings:")
                    for w in result["warnings"]:
                        print(f"    - {w}")
            else:
                print(f"  Error: {result['error']}")
            print()

        except ValueError:
            print("  Invalid input. Numbers only.\n")
        except KeyboardInterrupt:
            break
    print("\n  Done.\n")


def main():
    parser = argparse.ArgumentParser(description="Crop Recommendation Predictor v2")
    parser.add_argument("--N", type=float)
    parser.add_argument("--P", type=float)
    parser.add_argument("--K", type=float)
    parser.add_argument("--temperature", type=float)
    parser.add_argument("--humidity", type=float)
    parser.add_argument("--ph", type=float)
    parser.add_argument("--rainfall", type=float)
    parser.add_argument("--season_length", type=float)
    parser.add_argument("--altitude", type=float)
    parser.add_argument("--model", type=str, default=None)
    args = parser.parse_args()

    recommender = CropRecommender(args.model)

    if all(getattr(args, f, None) is not None for f in CropRecommender.ORIGINAL_FEATURES):
        res = recommender.predict(
            N=args.N, P=args.P, K=args.K,
            temperature=args.temperature, humidity=args.humidity,
            ph=args.ph, rainfall=args.rainfall,
            season_length=args.season_length, altitude=args.altitude
        )
        print(json.dumps(res, indent=2))
    else:
        interactive_mode(recommender)


if __name__ == "__main__":
    main()
