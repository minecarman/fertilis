import * as chatService from "../services/chat.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";

export const sendMessage = asyncHandler(async (req, res, next) => {
  const { message } = req.body;

  if (!message) {
    return next(new AppError("Message is required", 400));
  }

  const response = await chatService.fetchChatCompletion(message);
  const data = await response.json();

  const reply = data.choices?.[0]?.message?.content || "Cevap alınamadı";
  res.json({ reply });
});
