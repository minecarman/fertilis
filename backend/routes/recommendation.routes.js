import express from 'express';
import * as recommendationController from "../controllers/recommendation.controller.js";

const router = express.Router();

router.post('/', recommendationController.getFieldRecommendations);

export default router;