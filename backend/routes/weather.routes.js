import express from "express";
import * as weatherController from "../controllers/weather.controller.js";

const router = express.Router();

router.post("/", weatherController.getWeather);
router.post("/forecast", weatherController.getForecast);

export default router;