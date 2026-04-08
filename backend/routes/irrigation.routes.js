import express from "express";
import * as irrigationController from "../controllers/irrigation.controller.js";

const router = express.Router();

router.post("/", irrigationController.analyze);

export default router;
