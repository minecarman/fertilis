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
