import express from "express";
import axios from "axios";

const router = express.Router();

router.post("/", async (req, res) => {
  try {
    const { lat, lon } = req.body;

    const apiKey = process.env.OPENWEATHER_API_KEY;

    const url = `https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=metric&lang=tr&appid=${apiKey}`;

    const response = await axios.get(url);
    const data = response.data;

    res.json({
      temp: Math.round(data.main.temp),
      description: data.weather[0].description,
      humidity: data.main.humidity,
      wind: data.wind.speed,
      icon: data.weather[0].icon,
      city: data.name
    });

  } catch (error) {
    console.error("Weather Error:", error.message);
    res.status(500).json({ error: "Hava durumu sorunu" });
  }
});

export default router;