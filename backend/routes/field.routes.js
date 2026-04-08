import express from "express";
import * as fieldController from "../controllers/field.controller.js";

const router = express.Router();

router.post("/add", fieldController.addField);
router.get("/:email", fieldController.getFields);

export default router;