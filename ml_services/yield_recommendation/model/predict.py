import pandas as pd
import numpy as np
import joblib
import argparse
import sys

def predict(model_path, data_path, country, commodity):
    try:
        pipeline = joblib.load(model_path)
    except FileNotFoundError:
        print(f"Error: Model file '{model_path}' not found. Please run train.py first.")
        sys.exit(1)
        
    model = pipeline['model']
    label_encoders = pipeline['label_encoders']
    scaler = pipeline['scaler']
    features = pipeline['features']

    # Load data to find the historical context for the requested country/commodity
    df = pd.read_csv(data_path)
    
    # Filter for the specific country and commodity
    subset = df[(df['Country/Region'] == country) & (df['Commodity'] == commodity)]
    
    if subset.empty:
        print(f"Error: No data found for Country={country} and Commodity={commodity}.")
        sys.exit(1)
        
    # Get the latest available season to make the prediction
    # Assuming Season is formatted like '2025/26'
    latest_row = subset.sort_values(by='Season').iloc[-1:]
    latest_season = latest_row['Season'].values[0]
    
    print(f"Using historical data from Season: {latest_season} to predict the following year.")
    
    # Prepare the feature vector
    X_pred = latest_row[features].copy()

    # Apply Encoders
    for col, le in label_encoders.items():
        try:
            X_pred[col] = le.transform(X_pred[col])
        except ValueError:
            print(f"Error: Unseen label for {col}.")
            sys.exit(1)
            
    # Scale numeric features
    numeric_cols = [c for c in features if c not in label_encoders.keys()]
    X_pred[numeric_cols] = scaler.transform(X_pred[numeric_cols])

    # Predict
    prediction = model.predict(X_pred)[0]
    
    print("$" * 50)
    print(f"PREDICTION RESULTS FOR {commodity.upper()} IN {country.upper()}")
    print("$" * 50)
    print(f"Predicted Production for next year: {prediction:,.2f} Million tonnes")
    
    # Print the current year production for context
    if 'Production' in latest_row.columns:
        current_prod = float(latest_row['Production'].values[0])
        print(f"Current Year ({latest_season}) Production: {current_prod:,.2f} Million tonnes")
        diff = prediction - current_prod
        if diff > 0:
            print(f"Trend: ↑ Expected to increase by {diff:,.2f} Million tonnes")
        elif diff < 0:
            print(f"Trend: ↓ Expected to decrease by {abs(diff):,.2f} Million tonnes")
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
    predict(args.model, args.data, args.country, args.commodity)
