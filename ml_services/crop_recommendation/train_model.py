"""
Crop Recommendation Model — XGBoost Training Pipeline
===================================================
Production-quality ML pipeline focusing purely on an optimized XGBoost model
for the realistic (noisy/overlapping) Mediterranean & Global crop dataset.

Usage:
    python train_model.py                  # Full training pipeline
    python train_model.py --quick          # Quick mode (skip hyperparameter tuning)

Output:
    models/crop_model.pkl            # Trained model pipeline
    models/model_metadata.json       # Model info, feature names, crop list
    reports/training_report.png      # Training visualizations
"""

import os
import sys
import json
import time
import warnings
import argparse
from pathlib import Path
from datetime import datetime

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import joblib

from sklearn.model_selection import train_test_split, RandomizedSearchCV, StratifiedKFold
from sklearn.preprocessing import StandardScaler, LabelEncoder
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix, f1_score

try:
    from xgboost import XGBClassifier
    HAS_XGBOOST = True
except ImportError:
    HAS_XGBOOST = False
    print("XGBoost is required for this pipeline. Please `pip install xgboost`.")
    sys.exit(1)

warnings.filterwarnings("ignore")

# ── Paths ──────────────────────────────────────────────────────────────────────
PROJECT_ROOT = Path(__file__).resolve().parent
DATA_DIR = PROJECT_ROOT / "data"
MODELS_DIR = PROJECT_ROOT / "models"
REPORTS_DIR = PROJECT_ROOT / "reports"
DATA_FILE = DATA_DIR / "master_crop_dataset.csv"

# ── Config ─────────────────────────────────────────────────────────────────────
FEATURES = ["N", "P", "K", "temperature", "humidity", "ph", "rainfall", "season_length", "altitude"]
TARGET = "label"
RANDOM_STATE = 42
TEST_SIZE = 0.2
CV_FOLDS = 5


# ═══════════════════════════════════════════════════════════════════════════════
#  DATA PROCESSING
# ═══════════════════════════════════════════════════════════════════════════════

def load_data() -> pd.DataFrame:
    if not DATA_FILE.exists():
        print(f" Dataset not found at {DATA_FILE}. Run 'python generate_fao_simulated_data.py'.")
        sys.exit(1)

    df = pd.read_csv(DATA_FILE)
    print(f" Loaded {len(df)} samples across {df[TARGET].nunique()} crops")
    return df

def engineer_features(df: pd.DataFrame) -> pd.DataFrame:
    """ Agronomic feature engineering. """
    df = df.copy()
    df["npk_total"] = df["N"] + df["P"] + df["K"]
    npk_sum = df["npk_total"] + 1e-8
    df["n_ratio"] = df["N"] / npk_sum
    df["p_ratio"] = df["P"] / npk_sum
    df["k_ratio"] = df["K"] / npk_sum
    df["n_to_p"] = df["N"] / (df["P"] + 1e-8)
    df["n_to_k"] = df["N"] / (df["K"] + 1e-8)
    df["humidity_temp"] = df["humidity"] * df["temperature"] / 100
    df["rainfall_per_temp"] = df["rainfall"] / (df["temperature"] + 1e-8)
    df["ph_deviation_from_neutral"] = abs(df["ph"] - 7.0)
    # New v2 features
    df["rain_per_season"] = df["rainfall"] / (df["season_length"] + 1e-8)
    df["temp_altitude"] = df["temperature"] / (df["altitude"] + 1.0)  # higher altitude = cooler
    return df


# ═══════════════════════════════════════════════════════════════════════════════
#  XGBOOST MODEL
# ═══════════════════════════════════════════════════════════════════════════════

def tune_xgboost(X_train, y_train, quick=False):
    """
    Train and hyperparameter-tune XGBoost using RandomizedSearchCV.
    For this highly overlapped dataset, regularization helps avoid overfitting.
    """
    base_model = XGBClassifier(
        objective="multi:softprob",
        eval_metric="mlogloss",
        use_label_encoder=False,
        random_state=RANDOM_STATE,
        n_jobs=-1,
        verbosity=0
    )

    if quick:
        print(" Quick mode: Using tuned defaults.")
        base_model.set_params(
            n_estimators=300, max_depth=8, learning_rate=0.1,
            subsample=0.8, colsample_bytree=0.8, gamma=0.1,
            reg_alpha=0.1, reg_lambda=1
        )
        base_model.fit(X_train, y_train)
        return base_model

    # Extensive parameter grid optimized for realistic overlapping tabular data
    param_dist = {
        "n_estimators": [100, 200, 300, 500],
        "learning_rate": [0.01, 0.05, 0.1, 0.15],
        "max_depth": [4, 6, 8, 10],
        "min_child_weight": [1, 3, 5],
        "subsample": [0.6, 0.8, 1.0],
        "colsample_bytree": [0.6, 0.8, 1.0],
        "gamma": [0, 0.1, 0.5, 1],          # Crucial for preventing overfitting on noisy data
        "reg_alpha": [0, 0.1, 1, 5],        # L1 regularization
        "reg_lambda": [0, 1, 5, 10]         # L2 regularization
    }

    cv = StratifiedKFold(n_splits=CV_FOLDS, shuffle=True, random_state=RANDOM_STATE)
    
    search = RandomizedSearchCV(
        base_model,
        param_distributions=param_dist,
        n_iter=30,          # Try 30 combinations for better results
        scoring="accuracy",
        cv=cv,
        verbose=1,
        n_jobs=-1,
        random_state=RANDOM_STATE
    )

    start = time.time()
    search.fit(X_train, y_train)
    elapsed = time.time() - start

    print(f"\n Tuning completed in {elapsed:.1f}s")
    print(f" Best CV Accuracy: {search.best_score_:.4f}")
    print(f" Best Params: {search.best_params_}")

    return search.best_estimator_


# ═══════════════════════════════════════════════════════════════════════════════
#  EVALUATION & SAVING
# ═══════════════════════════════════════════════════════════════════════════════

def plot_report(y_test, y_pred, model, feature_names, label_encoder):
    REPORTS_DIR.mkdir(parents=True, exist_ok=True)
    fig = plt.figure(figsize=(18, 8))
    gs = fig.add_gridspec(1, 2, width_ratios=[1.5, 1])

    # Confusion matrix
    ax1 = fig.add_subplot(gs[0])
    cm = confusion_matrix(y_test, y_pred)
    crop_names = label_encoder.classes_
    sns.heatmap(cm, annot=True, fmt="d", cmap="Blues", ax=ax1,
                xticklabels=crop_names, yticklabels=crop_names, linewidths=0.5)
    ax1.set_xlabel("Predicted")
    ax1.set_ylabel("Actual")
    ax1.set_title("XGBoost Confusion Matrix")
    
    # Feature importance
    ax2 = fig.add_subplot(gs[1])
    importances = model.feature_importances_
    feat_imp = pd.Series(importances, index=feature_names).sort_values(ascending=True)
    ax2.barh(feat_imp.index, feat_imp.values, color="#3498db")
    ax2.set_xlabel("XGBoost Feature Importance")
    ax2.set_title("Feature Contributions")
    ax2.spines[["top", "right"]].set_visible(False)

    plt.tight_layout()
    plt.savefig(REPORTS_DIR / "xgboost_report.png", dpi=150)
    plt.close()
    print(" Saved xgboost_report.png")


def save_model(model, scaler, label_encoder, feature_names, accuracy):
    MODELS_DIR.mkdir(parents=True, exist_ok=True)
    model_package = {
        "model": model,
        "scaler": scaler,
        "label_encoder": label_encoder,
        "feature_names": feature_names,
    }
    model_path = MODELS_DIR / "crop_model.pkl"
    joblib.dump(model_package, model_path)
    
    metadata = {
        "model_type": "XGBoost Classifier",
        "dataset_type": "Realistic FAO/ISRIC Simulated (Noisy/Overlapped)",
        "accuracy": round(accuracy, 4),
        "crops": list(label_encoder.classes_),
        "num_crops": len(label_encoder.classes_),
        "features": feature_names,
        "trained_at": datetime.now().isoformat()
    }
    with open(MODELS_DIR / "model_metadata.json", "w") as f:
        json.dump(metadata, f, indent=2)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--quick", action="store_true", help="Skip tuning")
    args = parser.parse_args()

    print("\n═" * 60)
    print(" XGBOOST CROP RECOMMENDATION TRAINING")
    print("═" * 60)
    
    # Data pipeline
    df = load_data()
    df = engineer_features(df)
    feature_names = [c for c in df.columns if c != TARGET]
    
    X = df[feature_names].values
    label_encoder = LabelEncoder()
    y = label_encoder.fit_transform(df[TARGET])

    scaler = StandardScaler()
    X_scaled = scaler.fit_transform(X)

    X_train, X_test, y_train, y_test = train_test_split(
        X_scaled, y, test_size=TEST_SIZE, random_state=RANDOM_STATE, stratify=y
    )

    print(f"\n Training XGBoost on {len(X_train)} samples...")
    model = tune_xgboost(X_train, y_train, quick=args.quick)

    print("\n Evaluating on test set...")
    y_pred = model.predict(X_test)
    accuracy = accuracy_score(y_test, y_pred)
    f1 = f1_score(y_test, y_pred, average="weighted")
    
    print(f" Test Accuracy:  {accuracy:.4f}")
    print(f" Test F1-Score:  {f1:.4f}")
    
    print("\n Classification Report:")
    print(classification_report(y_test, y_pred, target_names=label_encoder.classes_))

    plot_report(y_test, y_pred, model, feature_names, label_encoder)
    save_model(model, scaler, label_encoder, feature_names, accuracy)

    print("\n Training Completed, model is saved in models/.")

if __name__ == "__main__":
    main()
