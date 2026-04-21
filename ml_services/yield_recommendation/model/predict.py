import pandas as pd
import joblib
import argparse
import sys
from pathlib import Path

class YieldPredictor:
    def __init__(self, model_path, data_path):
        model_path = Path(model_path)
        data_path = Path(data_path)

        if not model_path.exists():
            raise FileNotFoundError(f"Model file not found: {model_path}")
        if not data_path.exists():
            raise FileNotFoundError(f"Data file not found: {data_path}")

        pipeline = joblib.load(model_path)
        self.model = pipeline['model']
        self.label_encoders = pipeline['label_encoders']
        self.scaler = pipeline['scaler']
        self.features = pipeline['features']
        self.df = pd.read_csv(data_path)

    def _trend_text(self, diff):
        if diff > 0:
            return "increase"
        if diff < 0:
            return "decrease"
        return "stable"

    def predict(self, country, commodity):
        subset = self.df[(self.df['Country/Region'] == country) & (self.df['Commodity'] == commodity)]

        if subset.empty:
            raise ValueError(f"No data found for Country={country} and Commodity={commodity}.")

        latest_row = subset.sort_values(by='Season').iloc[-1:]
        latest_season = str(latest_row['Season'].values[0])

        # Prepare the feature vector
        X_pred = latest_row[self.features].copy()

        # Apply encoders
        for col, le in self.label_encoders.items():
            X_pred[col] = le.transform(X_pred[col])

        # Scale numeric features
        numeric_cols = [c for c in self.features if c not in self.label_encoders.keys()]
        X_pred[numeric_cols] = self.scaler.transform(X_pred[numeric_cols])

        prediction = float(self.model.predict(X_pred)[0])
        current_prod = float(latest_row['Production'].values[0]) if 'Production' in latest_row.columns else None
        diff = prediction - current_prod if current_prod is not None else None

        return {
            "country": country,
            "commodity": commodity,
            "latest_season": latest_season,
            "predicted_production_mt": round(prediction, 2),
            "current_production_mt": round(current_prod, 2) if current_prod is not None else None,
            "delta_mt": round(diff, 2) if diff is not None else None,
            "trend": self._trend_text(diff) if diff is not None else None,
        }


def predict(model_path, data_path, country, commodity):
    predictor = YieldPredictor(model_path=model_path, data_path=data_path)
    return predictor.predict(country=country, commodity=commodity)


def _print_prediction(result):
    print("$" * 50)
    print(f"PREDICTION RESULTS FOR {result['commodity'].upper()} IN {result['country'].upper()}")
    print("$" * 50)
    print(f"Using historical data from Season: {result['latest_season']} to predict the following year.")
    print(f"Predicted Production for next year: {result['predicted_production_mt']:,.2f} Million tonnes")
    if result['current_production_mt'] is not None:
        print(
            f"Current Year ({result['latest_season']}) Production: "
            f"{result['current_production_mt']:,.2f} Million tonnes"
        )
        if result['delta_mt'] is not None and result['delta_mt'] > 0:
            print(f"Trend: ↑ Expected to increase by {result['delta_mt']:,.2f} Million tonnes")
        elif result['delta_mt'] is not None and result['delta_mt'] < 0:
            print(f"Trend: ↓ Expected to decrease by {abs(result['delta_mt']):,.2f} Million tonnes")
        else:
            print(f"Trend: ↔ Expected to remain stable")

    print("-" * 50)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Predict Crop Production using trained model.")
    parser.add_argument("--model", "-m", type=str, default="amis_model.joblib", help="Path to trained model")
    parser.add_argument("--data", "-d", type=str, default="data_clean.csv", help="Path to clean CSV to read historical context")
    parser.add_argument("--country", "-c", type=str, required=True, help="Country/Region name (e.g. 'United States of America')")
    parser.add_argument("--commodity", "-y", type=str, required=True, help="Commodity name (e.g. 'Wheat', 'Maize')")
    
    args = parser.parse_args()
    try:
        prediction_result = predict(args.model, args.data, args.country, args.commodity)
        _print_prediction(prediction_result)
    except (FileNotFoundError, ValueError) as exc:
        print(f"Error: {exc}")
        sys.exit(1)
