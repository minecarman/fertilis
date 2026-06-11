"""Train the yield recommendation regressor on the cleaned FAO-style dataset.

The saved artifact stays compatible with :mod:`yield_recommendation.model.predict`.
"""

from __future__ import annotations

from pathlib import Path
import json
import math

import joblib
import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_absolute_error, mean_squared_error, r2_score
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder, StandardScaler


PROJECT_DIR = Path(__file__).resolve().parents[1]
DATA_PATH = PROJECT_DIR / "data" / "data_clean.csv"
MODEL_PATH = PROJECT_DIR / "model" / "amis_model.joblib"
METADATA_PATH = PROJECT_DIR / "model" / "amis_model.metadata.json"

TARGET = "Next_Year_Production"
FEATURES = [
    "Country/Region",
    "Commodity",
    "Area Harvested",
    "Closing Stocks",
    "Crush",
    "Domestic Supply",
    "Domestic Utilization",
    "Exports (ITY)",
    "Exports (NMY)",
    "Extraction Rate",
    "Feed Use",
    "Food Use",
    "Imports (ITY)",
    "Imports (NMY)",
    "Industrial Use",
    "Opening Stocks",
    "Other Uses",
    "Per Capita Food Use",
    "Production",
    "Production Paddy",
    "Residual",
    "Seeds",
    "Stocks to Use Ratio",
    "Supply",
    "Total Supply",
    "Total Utilization",
    "Trade",
    "Yield",
]


def load_dataset() -> pd.DataFrame:
    if not DATA_PATH.exists():
        raise FileNotFoundError(f"Data file not found: {DATA_PATH}")

    df = pd.read_csv(DATA_PATH)
    required_columns = FEATURES + [TARGET]
    missing_columns = [column for column in required_columns if column not in df.columns]
    if missing_columns:
        raise ValueError(f"Missing required columns: {missing_columns}")

    return df[required_columns].copy()


def prepare_training_frame(df: pd.DataFrame) -> pd.DataFrame:
    numeric_columns = [column for column in FEATURES if column not in {"Country/Region", "Commodity"}]
    cleaned = df.copy()

    for column in numeric_columns + [TARGET]:
        cleaned[column] = pd.to_numeric(cleaned[column], errors="coerce")

    cleaned["Country/Region"] = cleaned["Country/Region"].astype(str).str.strip()
    cleaned["Commodity"] = cleaned["Commodity"].astype(str).str.strip()
    cleaned = cleaned.dropna(subset=FEATURES + [TARGET])

    return cleaned


def fit_label_encoders(df: pd.DataFrame) -> dict[str, LabelEncoder]:
    encoders: dict[str, LabelEncoder] = {}
    for column in ["Country/Region", "Commodity"]:
        encoder = LabelEncoder()
        encoder.fit(df[column].astype(str))
        encoders[column] = encoder
    return encoders


def encode_features(df: pd.DataFrame, encoders: dict[str, LabelEncoder]) -> pd.DataFrame:
    encoded = df.copy()
    for column, encoder in encoders.items():
        encoded[column] = encoder.transform(encoded[column].astype(str))
    return encoded


def main() -> None:
    df = prepare_training_frame(load_dataset())
    label_encoders = fit_label_encoders(df)

    encoded = encode_features(df, label_encoders)
    X = encoded[FEATURES]
    y = encoded[TARGET]

    X_train, X_test, y_train, y_test = train_test_split(
        X,
        y,
        test_size=0.2,
        random_state=42,
    )

    scaler = StandardScaler()
    numeric_columns = [column for column in FEATURES if column not in label_encoders]
    X_train_scaled = X_train.copy()
    X_test_scaled = X_test.copy()
    X_train_scaled[numeric_columns] = scaler.fit_transform(X_train_scaled[numeric_columns])
    X_test_scaled[numeric_columns] = scaler.transform(X_test_scaled[numeric_columns])

    model = RandomForestRegressor(
        n_estimators=400,
        random_state=42,
        n_jobs=-1,
        min_samples_leaf=1,
    )
    model.fit(X_train_scaled, y_train)

    predictions = model.predict(X_test_scaled)
    metrics = {
        "mae": float(mean_absolute_error(y_test, predictions)),
        "rmse": float(math.sqrt(mean_squared_error(y_test, predictions))),
        "r2": float(r2_score(y_test, predictions)),
        "rows": int(len(df)),
        "countries": int(df["Country/Region"].nunique()),
        "commodities": int(df["Commodity"].nunique()),
        "commodity_list": sorted(df["Commodity"].astype(str).unique().tolist()),
    }

    MODEL_PATH.parent.mkdir(parents=True, exist_ok=True)
    joblib.dump(
        {
            "model": model,
            "label_encoders": label_encoders,
            "scaler": scaler,
            "features": FEATURES,
        },
        MODEL_PATH,
    )

    METADATA_PATH.write_text(json.dumps(metrics, indent=2), encoding="utf-8")

    print(f"Saved model to {MODEL_PATH}")
    print(f"MAE:  {metrics['mae']:.4f}")
    print(f"RMSE: {metrics['rmse']:.4f}")
    print(f"R2:   {metrics['r2']:.4f}")
    print(f"Crops: {metrics['commodities']}")


if __name__ == "__main__":
    main()