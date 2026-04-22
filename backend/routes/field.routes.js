import express from "express";
import * as fieldController from "../controllers/field.controller.js";

const router = express.Router();

router.post("/upload-image", fieldController.uploadFieldImage);
router.post("/add", fieldController.addField);
router.patch("/:fieldId", fieldController.updateFieldName);
router.get("/:email", fieldController.getFields);
router.delete("/:fieldId", fieldController.deleteField);

export default router;