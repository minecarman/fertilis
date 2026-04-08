import * as weatherService from "../services/weather.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const getWeather = asyncHandler(async (req, res, next) => {
  const { lat, lon } = req.body;
  if (!lat || !lon) {
    return next(new AppError("Koordinatlar gereklidir", 400));
  }
  const weatherData = await weatherService.fetchWeather(lat, lon);
  res.json(weatherData);
});

export const getForecast = asyncHandler(async (req, res, next) => {
  const { lat, lon } = req.body;
  if (!lat || !lon) {
    return next(new AppError("Koordinatlar gereklidir", 400));
  }
  const forecastData = await weatherService.fetchForecast(lat, lon);
  res.json(forecastData);
});
