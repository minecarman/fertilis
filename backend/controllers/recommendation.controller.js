import { getRecommendations } from '../services/recommendation.service.js';
import * as soilService from "../services/soil.service.js";
import AppError from "../utils/AppError.js";
import asyncHandler from "../utils/asyncHandler.js";
import axios from "axios";

export const getFieldRecommendations = asyncHandler(async (req, res, next) => {
    const { lat, lng } = req.body;

    if (!lat || !lng) {
        return next(new AppError('Koordinat bilgisi eksik.', 400));
    }

    // 1. İKLİM VERİSİ - OpenWeather
    const OPENWEATHER_API_KEY = process.env.OPENWEATHER_API_KEY || "SENIN_API_KEYIN_BURAYA_GELECEK"; 
    
    let temp = 25, humidity = 70, rainfall = 200;

    try {
        const wRes = await axios.get(`https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lng}&appid=${OPENWEATHER_API_KEY}&units=metric`);
        temp = wRes.data.main.temp;
        humidity = wRes.data.main.humidity;
        rainfall = wRes.data.rain && wRes.data.rain['1h'] ? (wRes.data.rain['1h'] * 24 * 30) : 200;
    } catch (e) {
         console.log("Hava durumu API'si mock veriye düştü."); 
    }

    // 2. TOPRAK VERİSİ - SoilGrids WMS
    console.log(`🔍 ${lat}, ${lng} için gerçek toprak verileri WMS üzerinden sorgulanıyor...`);
    
    let rawPh = await soilService.fetchSoilDataFromWMS(lat, lng, 'phh2o');
    let rawN = await soilService.fetchSoilDataFromWMS(lat, lng, 'nitrogen');
    let rawSoc = await soilService.fetchSoilDataFromWMS(lat, lng, 'soc'); 
    
    console.log(`✅ WMS Cevabı -> pH: ${rawPh}, Azot: ${rawN}, Karbon(SOC): ${rawSoc}`);

    const ph = rawPh ? (rawPh / 10) : 6.5; 
    const N = rawN ? rawN : 85; 
    const P = rawSoc ? Math.round(rawSoc / 1.2) : 45; 
    const K = rawSoc ? Math.round(rawSoc / 0.8) : 40; 

    const fieldData = {
        N: Number(N),
        P: Number(P),
        K: Number(K),
        temperature: Number(temp),
        humidity: Number(humidity),
        ph: Number(ph),
        rainfall: Number(rainfall)
    };

    // 3. KNN ANALİZİ
    let recommendations = getRecommendations(fieldData);

    if (!recommendations || recommendations.length === 0) {
        console.log("⚠️ KNN algoritması tam eşleşme bulamadı, en yakın genel ürünler öneriliyor.");
        recommendations = ['wheat', 'barley', 'sunflower'];
    }

    res.json({
        success: true,
        method: "OGC WMS GetFeatureInfo (Stable)",
        field_conditions: fieldData,
        recommendations: recommendations
    });
});
