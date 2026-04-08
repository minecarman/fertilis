import * as authService from "../services/auth.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const register = asyncHandler(async (req, res, next) => {
  const { full_name, email, password } = req.body;

  if (!email || !password || !full_name) {
    return next(new AppError("Tüm alanları doldurunuz.", 400));
  }
  if (password.length < 6) {
    return next(new AppError("Şifre en az 6 karakter olmalıdır.", 400));
  }

  try {
    const newUser = await authService.registerUser(full_name, email, password);
    console.log("yeni kullanıcı:", email);
    res.status(201).json({ message: "Kayıt başarılı", user: newUser });
  } catch (e) {
    const statusCode = e.message.includes("zaten kayıtlı") ? 400 : 500;
    return next(new AppError(e.message, statusCode));
  }
});

export const login = asyncHandler(async (req, res, next) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return next(new AppError("E-posta ve şifre gereklidir.", 400));
  }

  try {
    const user = await authService.loginUser(email, password);
    console.log("Giriş Başarılı:", user.full_name);
    res.json({ message: "Giriş başarılı", user });
  } catch (e) {
    const statusCode = e.message.includes("hatalı") ? 401 : 500;
    return next(new AppError(e.message, statusCode));
  }
});

export const updateProfile = asyncHandler(async (req, res, next) => {
  const { old_email, new_email, full_name } = req.body;

  if (!old_email || !new_email || !full_name) {
    return next(new AppError("Tüm alanlar gereklidir.", 400));
  }

  try {
    const updatedUser = await authService.updateUserProfile(old_email, new_email, full_name);
    res.json({ message: "Profil başarıyla güncellendi.", user: updatedUser });
  } catch (e) {
    const statusCode = e.message.includes("başka bir hesap") ? 400 : 500;
    return next(new AppError(e.message, statusCode));
  }
});
