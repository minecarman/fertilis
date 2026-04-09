import * as chatService from "../services/chat.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const sendMessage = asyncHandler(async (req, res, next) => {
  const { message } = req.body;

  if (!message) {
    return next(new AppError("Message is required", 400));
  }

  try {
    const reply = await chatService.fetchChatCompletion(message);
    res.json({ reply });
  } catch (error) {
    return next(new AppError(`Chat servisi hatasi: ${error.message}`, 502));
  }
});
