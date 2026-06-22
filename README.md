# Fertilis: Smart Mobile Agriculture Assistant

![Fertilis Architecture](https://img.shields.io/badge/Architecture-Microservices-blue)
![Flutter](https://img.shields.io/badge/Frontend-Flutter-02569B?logo=flutter&logoColor=white)
![Node.js](https://img.shields.io/badge/Backend-Node.js-339933?logo=nodedotjs&logoColor=white)
![Python](https://img.shields.io/badge/ML-FastAPI_&_XGBoost-3776AB?logo=python&logoColor=white)
![Supabase](https://img.shields.io/badge/Database-Supabase-3ECF8E?logo=supabase&logoColor=white)

**Fertilis** is a comprehensive, cross-platform mobile and web application engineered to enhance agricultural productivity through data-driven AI. By leveraging real-time meteorology, machine learning, and physical hydrology, Fertilis replaces guesswork with precision agriculture.

---

## Key Features

1. **Crop Recommendation Engine (XGBoost)**
   - Utilizes a synthesized Kaggle + TÜİK/TAGEM dataset of 50,000+ records.
   - Evaluates N, P, K, pH, Temperature, Humidity, and Rainfall.
   - Queries live data from the **SoilGrids REST API** and **NASA POWER API** based on the user's GPS centroid.
2. **Macroeconomic Yield Predictor**
   - Buffers farmers against market volatility using FAO AMIS data.
   - Leverages a "Delta Paradigm" to forecast supply chain anomalies (change in harvest tonnage) rather than just autoregressive historical data.
3. **Precision Irrigation Engine (FAO-56 & USDA-SCS)**
   - **Crop Evapotranspiration ($ET_c$):** Uses the FAO-56 Dual Crop Coefficient method to separate plant transpiration ($K_{cb}$) from soil evaporation ($K_e$) using live satellite volumetric water content.
   - **Effective Rainfall ($P_e$):** Employs the USDA-SCS Curve Number hydrology method to deduct surface runoff and calculate pure root-zone infiltration.
4. **Smart Polygon Mapping**
   - Users draw field borders natively on an interactive map. The app calculates the mathematical centroid of the polygon to query highly localized environmental data.

---

## Architecture

Fertilis operates on a decoupled microservices architecture:
- **Frontend (Flutter):** Provides native performance on iOS, Android, and Web.
- **Middleware (Node.js/Express):** Manages external APIs (OpenWeather, OpenRouter Llama 3.3) and acts as the central router.
- **Database (Supabase):** Securely stores encrypted authentication layers, spatial field coordinates, and historical agricultural logs.
- **Machine Learning (Python/FastAPI):** Hosts the XGBoost classifiers, regressors, and the physical FAO-56 hydrology engine.

---

## Getting Started

### Prerequisites
- Node.js (v18+)
- Python (v3.10+)
- Flutter SDK
- A Supabase Project URL & API Key

### 1. Python ML Service Setup
```bash
cd ml_services
python -m venv venv
# Windows: venv\Scripts\activate | Mac/Linux: source venv/bin/activate
pip install -r requirements.txt
python app.py
```
*Runs on `http://127.0.0.1:5000`*

### 2. Node.js Backend Setup
```bash
cd backend
npm install
```
Create a `.env` file in the `backend/` directory:
```env
PORT=3000
SUPABASE_URL=your_supabase_url
SUPABASE_ANON_KEY=your_supabase_anon_key
ML_SERVICE_URL=http://127.0.0.1:5000
```
Start the server:
```bash
node app.js
```
*Runs on `http://localhost:3000`*

### 3. Flutter Frontend Setup
```bash
cd frontend
flutter pub get
flutter run
```

---

## Datasets & References
* **FAO-56 Irrigation Standard:** Allen et al. (1998)
* **USDA-SCS Hydrology:** National Engineering Handbook (2004)
* **Crop Recommender Dataset:** Kaggle (Atharva Ingle) & TÜİK/TAGEM
* **Yield Predictor Data:** FAO AMIS Database
* **APIs Used:** SoilGrids, NASA POWER, Open-Meteo, OpenWeatherMap, OpenRouter (Llama 3.3).

---
*Built as a Senior Design Capstone Project by Arda AKÇA & Muhammed AVCI, Muğla Sıtkı Koçman University.*
