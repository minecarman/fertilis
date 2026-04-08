import pandas as pd
import numpy as np

def rebuild():
    # Eski veri setini okuyalim
    df = pd.read_csv('data/master_crop_dataset.csv')

    np.random.seed(42)

    # Kategoriler ve iklim sezonu atamalari:
    mediterranean_crops = ['olive', 'fig', 'citrus', 'orange', 'grape', 'pomegranate', 'almond']
    continental_crops = ['wheat', 'barley', 'chickpea', 'lentil', 'apple', 'sunflower', 'sugarbeet', 'potato', 'onion']
    tropical_crops = ['mango', 'banana', 'papaya', 'coconut', 'coffee', 'cotton', 'rice', 'jute', 'sugarcane']

    temp_summers = []
    temp_winters = []
    rain_summers = []
    rain_winters = []
    altitudes = []

    for idx, row in df.iterrows():
        label = row['label']
        T = row['temperature']
        R = row['rainfall']
        alt = row['altitude']
        
        if label in mediterranean_crops:
            ts = T + np.random.uniform(6, 12)
            tw = max(T - np.random.uniform(6, 12), 4.0) 
            rs = R * np.random.uniform(0.05, 0.15)
            rw = R * np.random.uniform(0.40, 0.80)
            if label == 'olive': alt = np.random.uniform(5, 800)
            elif label == 'citrus': alt = np.random.uniform(0, 300)

        elif label in continental_crops:
            ts = T + np.random.uniform(8, 14)
            tw = T - np.random.uniform(12, 18)
            rs = R * np.random.uniform(0.15, 0.35)
            rw = R * np.random.uniform(0.30, 0.50)
            if label == 'wheat': alt = np.random.uniform(200, 1800)

        elif label in tropical_crops:
            ts = T + np.random.uniform(1, 4)
            tw = max(T - np.random.uniform(1, 5), 18.0) 
            rs = R * np.random.uniform(0.50, 0.80)
            rw = R * np.random.uniform(0.10, 0.25)
            alt = np.random.uniform(0, 600)

        else:
            ts = T + np.random.uniform(4, 9)
            tw = T - np.random.uniform(6, 12)
            rs = R * np.random.uniform(0.2, 0.4)
            rw = R * np.random.uniform(0.2, 0.4)

        temp_summers.append(round(ts, 2))
        temp_winters.append(round(tw, 2))
        rain_summers.append(round(rs, 2))
        rain_winters.append(round(rw, 2))
        altitudes.append(round(alt, 2))

    df['temp_summer'] = temp_summers
    df['temp_winter'] = temp_winters
    df['rain_summer'] = rain_summers
    df['rain_winter'] = rain_winters
    df['altitude'] = altitudes

    df.drop(columns=['temperature', 'rainfall', 'humidity', 'season_length'], inplace=True, errors='ignore')

    cols = ['N', 'P', 'K', 'ph', 'temp_summer', 'temp_winter', 'rain_summer', 'rain_winter', 'altitude', 'label']
    df = df[cols]

    df.to_csv('data/seasonal_crop_dataset.csv', index=False)
    print("Mevsimsel veri seti hazırlandı! Features: N, P, K, ph, temp_summer, temp_winter, rain_summer, rain_winter, altitude")

if __name__ == "__main__":
    rebuild()