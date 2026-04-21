import express from "express";
import * as yieldController from "../controllers/yield.controller.js";

const router = express.Router();

router.post("/", yieldController.predict);

export default router;
