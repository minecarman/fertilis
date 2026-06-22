/**
 * Irrigation Controller
 * 
 * Handles incoming HTTP requests for irrigation analysis. 
 * Responsibilities include:
 * - Validating incoming coordinate and crop strings.
 * - Safely handling potential missing fields (e.g., throwing 400 Bad Request).
 * - Passing clean data to the irrigation service layer.
 */
import * as irrigationService from "../services/irrigation.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const analyze = asyncHandler(async (req, res, next) => {
  // Extract inputs from the frontend's POST payload
  const { lat, lon, crop, last_irrigated_days } = req.body;

  // 1. Validate geographical coordinates
  if (lat === undefined || lon === undefined) {
    return next(new AppError("lat ve lon zorunludur", 400));
  }

  // 2. Validate crop string existence
  if (typeof crop !== "string" || !crop.trim()) {
    return next(new AppError("crop zorunludur", 400));
  }

  // 3. Validate days since last irrigated
  if (last_irrigated_days === undefined || last_irrigated_days === null || last_irrigated_days === "") {
    return next(new AppError("last_irrigated_days zorunludur", 400));
  }

  // 4. Safely parse inputs into numeric types
  const parsedLat = Number(lat);
  const parsedLon = Number(lon);
  const parsedLastIrrigatedDays = Number(last_irrigated_days);

  // Ensure parsing didn't result in NaN (Not a Number) and days are not negative
  if (Number.isNaN(parsedLat) || Number.isNaN(parsedLon) || Number.isNaN(parsedLastIrrigatedDays) || parsedLastIrrigatedDays < 0) {
    return next(new AppError("lat, lon ve last_irrigated_days sayisal ve pozitif olmalidir", 400));
  }
  
  try {
    // Forward the sanitized inputs to the service layer for ML processing
    const result = await irrigationService.analyzeIrrigation(parsedLat, parsedLon, crop.trim(), parsedLastIrrigatedDays);
    res.json(result);
  } catch (e) {
    // Forward any errors from the Python ML service down to the client gracefully
    const statusCode = e?.response?.status || 500;
    const detail = e?.response?.data?.detail || e?.response?.data?.message || e.message || "Sulama analizi yapilamadi";
    return next(new AppError(detail, statusCode));
  }
});
