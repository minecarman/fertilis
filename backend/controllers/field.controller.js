import * as fieldService from "../services/field.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const addField = asyncHandler(async (req, res, next) => {
  const { user_email, name, area, coordinates, crop, image_url } = req.body;

  if (!user_email || !coordinates) {
    return next(new AppError("Eksik bilgi.", 400));
  }

  const field = await fieldService.addField(user_email, name, area, coordinates, crop, image_url);
  res.status(201).json({ message: "Tarla kaydedildi!", field });
});

export const getFields = asyncHandler(async (req, res, next) => {
  const { email } = req.params;
  const data = await fieldService.getFieldsByUserEmail(email);
  res.json(data);
});

export const deleteField = asyncHandler(async (req, res, next) => {
  const { fieldId } = req.params;

  if (!fieldId) {
    return next(new AppError("Tarla ID gerekli.", 400));
  }

  await fieldService.deleteField(fieldId);
  res.status(200).json({ message: "Tarla başarıyla silindi!" });
});

export const updateFieldName = asyncHandler(async (req, res, next) => {
  const { fieldId } = req.params;
  const { name } = req.body;

  if (!fieldId) {
    return next(new AppError("Tarla ID gerekli.", 400));
  }

  const field = await fieldService.updateFieldName({ fieldId, name });
  res.status(200).json({ message: "Tarla adı güncellendi!", field });
});

export const uploadFieldImage = asyncHandler(async (req, res, next) => {
  const { user_email, image_base64, file_name, field_id } = req.body;

  console.log('[field.uploadFieldImage] request received', {
    hasUserEmail: Boolean(user_email),
    hasImageBase64: Boolean(image_base64),
    file_name,
    field_id,
    bodyKeys: Object.keys(req.body || {}),
  });

  if (!user_email || !image_base64) {
    return next(new AppError("user_email ve image_base64 gerekli.", 400));
  }

  const imageUrl = await fieldService.uploadFieldImage({ user_email, image_base64, file_name, field_id });
  console.log('[field.uploadFieldImage] upload complete', { imageUrl });
  res.status(201).json({ image_url: imageUrl });
});
