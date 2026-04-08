import axios from "axios";

export const analyzeIrrigation = async (lat, lon) => {
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

  return {
    rain: totalRain.toFixed(2),
    decision,
  };
};
