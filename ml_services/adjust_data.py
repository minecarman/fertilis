import pandas as pd
import numpy as np

# Veri setini oku
df = pd.read_csv('crop_recommendation/data/master_crop_dataset.csv')

np.random.seed(42) # Her seferinde aynı rastgele dağılımı almak için

# Çakışan veya Türkiye koşullarına uymayan bitkiler için 
# "Gerçekçi ve Genişletilmiş Öğrenme Aralıkları" tanımlıyoruz
adjustments = {
    'olive': {  # Zeytin: Ege ve Akdeniz'in yüksek kış yağışlarını (1000mm'ye kadar) çok rahat kaldırabilir, yazları kurak sever
        'temperature': (15.0, 25.0), # Muğla/Aydın yıllık ortalamaları genelde 17-20 civarıdır
        'rainfall': (400.0, 1050.0), # Muğla 800+mm yağış alır
        'N': (20.0, 70.0), 'P': (15.0, 60.0), 'K': (40.0, 100.0)
    },
    'fig': {    # İncir: Zeytine benzer ama biraz daha nemli/ılık yerlerde de olur
        'temperature': (16.0, 24.0),
        'rainfall': (500.0, 900.0), 
        'N': (30.0, 60.0), 'P': (20.0, 50.0), 'K': (30.0, 70.0)
    },
    'mango': {  # Mango: Aşırı tropikal, bol yağmur ve devasa sıcaklık (Böylece Hatay'da çıkmaz)
        'temperature': (27.0, 38.0),
        'rainfall': (1200.0, 2800.0), 
        'N': (80.0, 120.0), 'P': (20.0, 60.0), 'K': (40.0, 60.0)
    },
    'citrus': { # Narenciye: Ege/Akdeniz sıcaklıkları ve nispeten fazla su
        'temperature': (16.0, 25.0),
        'rainfall': (600.0, 1050.0),
        'N': (70.0, 100.0), 'P': (20.0, 40.0), 'K': (40.0, 60.0)
    },
    'cotton': { # Pamuk: Aşırı sıcak, yüksek besin
        'temperature': (24.0, 35.0),
        'rainfall': (450.0, 800.0),
        'N': (100.0, 140.0), 'P': (40.0, 60.0), 'K': (70.0, 90.0)
    },
    'wheat': {  # Buğday: Karasal, nispeten serin, düşük yağış
        'temperature': (10.0, 24.0),
        'rainfall': (300.0, 500.0),
        'N': (60.0, 90.0), 'P': (30.0, 50.0), 'K': (30.0, 50.0)
    },
    'maize': {  # Mısır: Sıcaktan ziyade ılıman, oldukça yüksek su isteği
        'temperature': (20.0, 30.0),
        'rainfall': (550.0, 850.0),
        'N': (80.0, 120.0), 'P': (40.0, 60.0), 'K': (40.0, 60.0)
    }
}

for label, ranges in adjustments.items():
    mask = df['label'] == label
    n_rows = mask.sum()
    if n_rows > 0:
        for col, (min_val, max_val) in ranges.items():
            df.loc[mask, col] = np.random.uniform(min_val, max_val, n_rows)

df.to_csv('crop_recommendation/data/master_crop_dataset.csv', index=False)
print("Gerçekçi ürün varyansları ve sınırları dataset'e başarıyla uygulandı!")