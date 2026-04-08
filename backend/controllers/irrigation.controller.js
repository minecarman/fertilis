import * as irrigationService from "../services/irrigation.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const analyze = asyncHandler(async (req, res, next) => {
  const { lat, lon } = req.body;
  
  try {
    const result = await irrigationService.analyzeIrrigation(lat, lon);
    res.json(result);
  } catch (e) {
    return next(new AppError("Konumu kontrol et", 500));
  }
});
