# Crop Recommendation Module

This folder contains the data generation, training, prediction, and smoke-test scripts for the crop recommendation system. File names have intentionally been kept as they are.

## Files in this folder

### `generate_fao_simulated_data.py`
Generates synthetic data inspired by FAO-style agronomic patterns and realistic growing conditions.

What it does:
- Creates confusion clusters for 15 crops.
- Generates values for N, P, K, temperature, humidity, pH, rainfall, season length, and altitude.
- Creates or updates `data/master_crop_dataset.csv`.

When to use it:
- When you need fresh training data.
- When you want to regenerate the dataset from scratch.

### `generate_nasa_dataset.py`
Collects real-world data from NASA POWER, ISRIC SoilGrids, and Open Elevation.

What it does:
- Collects climate data for real agricultural regions.
- Adds supporting values such as pH and altitude.
- Writes the collected records to `data/master_crop_dataset.csv`.

When to use it:
- When you want to enrich the dataset with real-world observations.
- When you want to mix simulated and real data.

### `train_model.py`
Trains the crop recommendation model.

What it does:
- Reads `data/master_crop_dataset.csv`.
- Applies feature engineering.
- Trains an XGBoost model.
- Saves the result as `models/crop_model.pkl`.
- Saves model metadata to `models/model_metadata.json`.
- Writes training reports into `reports/`.

When to use it:
- After the dataset has been updated.
- When you want to retrain the model.

Example run:
- `python train_model.py --quick`

### `predict_crop.py`
Prediction engine. It loads the trained model and generates crop recommendations for a new input row.

What it does:
- Loads the saved model.
- Validates input values.
- Produces a single prediction.
- Returns top-k recommendations with confidence scores.
- Also provides an interactive CLI mode.

When to use it:
- When you want to test predictions outside the API.
- When you want a recommendation for a single sample.

Example run:
- `python predict_crop.py`
- `python predict_crop.py --N 40 --P 15 --K 50 --temperature 18 --humidity 55 --ph 7.8 --rainfall 500 --season_length 240 --altitude 350`

### `test_prediction_smoke.py`
A quick validation script.

What it does:
- Instantiates `CropRecommender` through `predict_crop.py`.
- Runs prediction checks with sample scenarios such as olive, rice, and wheat.
- Verifies that the model and data path are working correctly.

When to use it:
- When you want a fast sanity check after changes.

## Data flow

1. `generate_fao_simulated_data.py` can generate synthetic data.
2. `generate_nasa_dataset.py` can add real-world data.
3. All data is collected in `data/master_crop_dataset.csv`.
4. `train_model.py` trains the model from that dataset.
5. `predict_crop.py` uses the trained model to make predictions.

## Output files

- `data/master_crop_dataset.csv` -> main training and data repository
- `models/crop_model.pkl` -> trained model package
- `models/model_metadata.json` -> model metadata
- `reports/` -> training reports and plots

## Run note

The scripts in this folder are best run from the project root. Example:

- `venv\\Scripts\\python.exe crop_recommendation\\train_model.py --quick`
- `venv\\Scripts\\python.exe crop_recommendation\\predict_crop.py`
- `venv\\Scripts\\python.exe crop_recommendation\\test_prediction_smoke.py`

## Short summary

- `generate_*` files create or collect data.
- `train_model.py` trains the model.
- `predict_crop.py` makes predictions with the trained model.
- `test_prediction_smoke.py` is used for quick validation.
