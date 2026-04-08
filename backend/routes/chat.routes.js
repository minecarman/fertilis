import express from "express";
import * as chatController from "../controllers/chat.controller.js";

const router = express.Router();

router.post("/", chatController.sendMessage);

export default router;
