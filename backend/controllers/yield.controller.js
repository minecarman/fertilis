import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";
import * as yieldService from "../services/yield.service.js";

function normalizeCountryName(country) {
  const normalized = country.trim();
  const aliases = {
    Turkey: "Türkiye",
    Turkiye: "Türkiye",
    "Türkiye": "Türkiye",
  };

  return aliases[normalized] || normalized;
}

export const predict = asyncHandler(async (req, res, next) => {
  const { commodity, country, lat, lng } = req.body;

  if (!commodity) {
    return next(new AppError("commodity zorunludur", 400));
  }

  const hasCountry = typeof country === "string" && country.trim().length > 0;
  const hasCoordinates = lat !== undefined && lng !== undefined;

  if (!hasCountry && !hasCoordinates) {
    return next(new AppError("country veya lat/lng saglanmalidir", 400));
  }

  const payload = {
    commodity,
  };

  if (hasCountry) {
    payload.country = normalizeCountryName(country);
  }

  if (hasCoordinates) {
    const parsedLat = Number(lat);
    const parsedLng = Number(lng);

    if (Number.isNaN(parsedLat) || Number.isNaN(parsedLng)) {
      return next(new AppError("lat ve lng sayisal olmalidir", 400));
    }

    payload.lat = parsedLat;
    payload.lng = parsedLng;
  }

  try {
    const result = await yieldService.predictYield(payload);
    return res.json(result);
  } catch (e) {
    const statusCode = e?.response?.status || 500;
    const detail = e?.response?.data?.detail || e?.response?.data?.message || e.message || "Yield tahmini yapilamadi";
    return next(new AppError(detail, statusCode));
  }
});
