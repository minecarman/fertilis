import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";
import axios from "axios";

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
            recs = result.recommendation.map(r => ({
                name: r.crop,
                confidence: (r.confidence * 100).toFixed(1),
                planting_calendar: r.planting_calendar || "Bilgi bulunamadı."
            })).slice(0, 5);
        } else if (result?.recommendation?.recommendations) {
            // Eski format (Eski prediction_crop.py)
            recs = result.recommendation.recommendations.map(r => ({
                name: r.crop,
                confidence: (r.confidence * 100).toFixed(1)
            })).slice(0, 3);
        }

        if (!recs || recs.length === 0) {
            console.log("ML Servisi urun bulamadi, genel urunler donuluyor.");
            recs = [
                { name: "wheat", confidence: 85 }, 
                { name: "barley", confidence: 80 }, 
                { name: "sunflower", confidence: 75 }
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
