import * as irrigationService from "../services/irrigation.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const analyze = asyncHandler(async (req, res, next) => {
  const { lat, lon, crop, last_irrigated_days } = req.body;

  if (lat === undefined || lon === undefined) {
    return next(new AppError("lat ve lon zorunludur", 400));
  }

  if (typeof crop !== "string" || !crop.trim()) {
    return next(new AppError("crop zorunludur", 400));
  }

  if (last_irrigated_days === undefined || last_irrigated_days === null || last_irrigated_days === "") {
    return next(new AppError("last_irrigated_days zorunludur", 400));
  }

  const parsedLat = Number(lat);
  const parsedLon = Number(lon);
  const parsedLastIrrigatedDays = Number(last_irrigated_days);

  if (Number.isNaN(parsedLat) || Number.isNaN(parsedLon) || Number.isNaN(parsedLastIrrigatedDays) || parsedLastIrrigatedDays < 0) {
    return next(new AppError("lat, lon ve last_irrigated_days sayisal ve pozitif olmalidir", 400));
  }
  
  try {
    const result = await irrigationService.analyzeIrrigation(parsedLat, parsedLon, crop.trim(), parsedLastIrrigatedDays);
    res.json(result);
  } catch (e) {
    return next(new AppError("Sulama analizi yapilamadi", 500));
  }
});
