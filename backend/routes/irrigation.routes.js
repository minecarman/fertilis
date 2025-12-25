import express from "express";
import axios from "axios";

const router = express.Router();

router.post("/irrigation", async (req, res) => {
  try {
    const { lat, lon } = req.body;

    const apiKey = process.env.OPENWEATHER_API_KEY;

    const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=metric&appid=${apiKey}`;

    const response = await axios.get(url);

    const forecastList = response.data.list;

    // Önümüzdeki 24 saat (ilk 8 adet 3 saatlik veri)
    let totalRain = 0;

    for (let i = 0; i < 8; i++) {
      totalRain += forecastList[i]?.rain?.["3h"] || 0;
    }

    let decision; // karar kısmı
    if (totalRain >= 5) {
      decision = "Bugün hava yağışlı olacak sulamaya gerek yok";
    } else if (totalRain >= 2) {
      decision = "Az yağış var biraz sula.";
    } else {
      decision = "sulama gerekli";
    }

    res.json({
      rain: totalRain.toFixed(2),
      decision,
    });
  } catch (e) { // lat lon inputta hata olursa
    res.status(500).json({
      rain: "N/A",
      decision: "Konumu kontrol et",
    });
  }
});

export default router;
