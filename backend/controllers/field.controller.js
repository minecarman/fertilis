import * as fieldService from "../services/field.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const addField = asyncHandler(async (req, res, next) => {
  const { user_email, name, area, coordinates } = req.body;

  if (!user_email || !coordinates) {
    return next(new AppError("Eksik bilgi.", 400));
  }

  const field = await fieldService.addField(user_email, name, area, coordinates);
  res.status(201).json({ message: "Tarla kaydedildi!", field });
});

export const getFields = asyncHandler(async (req, res, next) => {
  const { email } = req.params;
  const data = await fieldService.getFieldsByUserEmail(email);
  res.json(data);
});
