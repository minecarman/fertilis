import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";
import axios from "axios";

const buildRecommendationRate = (index) => {
    const baseRate = 92;
    const step = 12;
    const floorRate = 40;
    return Math.max(floorRate, baseRate - (index * step));
};

export const getFieldRecommendations = asyncHandler(async (req, res, next) => {
    const { lat, lng } = req.body;
    if (!lat || !lng) { return next(new AppError("Koordinat bilgisi eksik.", 400)); }

    try {
        console.log(`ML Servisine istek atiliyor... Lat: ${lat}, Lng: ${lng}`);
        const mlServiceUrl = process.env.ML_SERVICE_URL || "http://127.0.0.1:5000";
        const mlResponse = await axios.post(`${mlServiceUrl}/recommend_by_location`, {
            lat: parseFloat(lat),
            lng: parseFloat(lng),
            season_length: 150,
            altitude: 200
        });

        const result = mlResponse.data;
        let recs = [];
        if (Array.isArray(result?.recommendation)) {
            // Yeni format (Array). İlk 5 ürünü listeliyoruz.
            recs = result.recommendation.map((r, index) => ({
                name: r.crop,
                confidence: (r.confidence * 100).toFixed(1),
                recommendation_rate: buildRecommendationRate(index),
                planting_calendar: r.planting_calendar || "Bilgi bulunamadı."
            })).slice(0, 5);
        } else if (result?.recommendation?.recommendations) {
            // Eski format (Eski prediction_crop.py)
            recs = result.recommendation.recommendations.map((r, index) => ({
                name: r.crop,
                confidence: (r.confidence * 100).toFixed(1),
                recommendation_rate: buildRecommendationRate(index)
            })).slice(0, 3);
        }

        if (!recs || recs.length === 0) {
            console.log("ML Servisi urun bulamadi, genel urunler donuluyor.");
            recs = [
                { name: "wheat", confidence: 85, recommendation_rate: 92 }, 
                { name: "barley", confidence: 80, recommendation_rate: 80 }, 
                { name: "sunflower", confidence: 75, recommendation_rate: 68 }
            ];
        }

        res.json({
            success: true,
            method: "ML Microservice & OGC WMS GetFeatureInfo",
            field_conditions: result.features || {},
            recommendations: recs
        });
    } catch (error) {
        console.error("ML Servisi Hatasi:", error.response?.data || error.message);
        return next(new AppError("ML Servisine baglanirken veya analiz yapilirken hata olustu: " + error.message, 500));
    }
});
