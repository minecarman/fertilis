import axios from "axios";

export const fetchWeather = async (lat, lon) => {
  const apiKey = process.env.OPENWEATHER_API_KEY;
  const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&lang=tr&appid=${apiKey}`;

  const response = await axios.get(url);
  const data = response.data;

  return {
    temp: Math.round(data.main.temp),
    description: data.weather[0].description,
    humidity: data.main.humidity,
    wind: data.wind.speed,
    icon: data.weather[0].icon,
    city: data.name
  };
};

export const fetchForecast = async (lat, lon) => {
  const apiKey = process.env.OPENWEATHER_API_KEY;
  // OpenWeather 5 Day / 3 Hour Forecast API (gives 40 timestamps)
  const url = `https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=metric&lang=tr&appid=${apiKey}`;

  const response = await axios.get(url);
  const list = response.data.list;
  
  // Her gün için öğle saatine (veya ilk veri noktasına) karşılık gelen tahmini alalım.
  // 5 günlük veri döner (ücretsiz api), her gün için yaklaşık 1 tahmin alarak gruplayacağız.
  const dailyForecasts = [];
  const addedDays = new Set();
  
  for (const item of list) {
    const dateText = item.dt_txt.split(" ")[0]; // "YYYY-MM-DD"
    if (!addedDays.has(dateText)) {
      addedDays.add(dateText);
      dailyForecasts.push({
        date: dateText,
        temp: Math.round(item.main.temp),
        description: item.weather[0].description,
        icon: item.weather[0].icon,
        humidity: item.main.humidity,
        wind: item.wind.speed
      });
      // 7 gün istenmiş ancak ücretsiz api 5 gün verir. Bunu 5 ile sınırlı tutuyoruz veya elimizde ne varsa dönüyoruz.
    }
  }

  return {
    city: response.data.city.name,
    forecast: dailyForecasts.slice(0, 7) // 7 günlük veya ne kadar varsa
  };
};
