import * as irrigationService from "../services/irrigation.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const analyze = asyncHandler(async (req, res, next) => {
  const { lat, lon } = req.body;

  if (lat === undefined || lon === undefined) {
    return next(new AppError("lat ve lon zorunludur", 400));
  }

  const parsedLat = Number(lat);
  const parsedLon = Number(lon);

  if (Number.isNaN(parsedLat) || Number.isNaN(parsedLon)) {
    return next(new AppError("lat ve lon sayisal olmalidir", 400));
  }
  
  try {
    const result = await irrigationService.analyzeIrrigation(parsedLat, parsedLon);
    res.json(result);
  } catch (e) {
    return next(new AppError("Sulama analizi yapilamadi", 500));
  }
});
