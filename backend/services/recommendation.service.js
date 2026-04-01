import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

function loadCropData() {
    const csvFilePath = path.join(__dirname, '../data/Crop_recommendation.csv'); 
    const csvData = fs.readFileSync(csvFilePath, 'utf-8');
    
    const lines = csvData.split('\n');
    const crops = [];
    
    for (let i = 1; i < lines.length; i++) {
        if (!lines[i].trim()) continue;
        
        const [n, p, k, temp, hum, ph, rain, label] = lines[i].split(',');
        
        crops.push({
            N: parseFloat(n),
            P: parseFloat(p),
            K: parseFloat(k),
            temperature: parseFloat(temp),
            humidity: parseFloat(hum),
            ph: parseFloat(ph),
            rainfall: parseFloat(rain),
            label: label ? label.trim() : ''
        });
    }
    return crops;
}

function calculateDistance(field, crop) {
    return Math.sqrt(
        Math.pow(field.N - crop.N, 2) +
        Math.pow(field.P - crop.P, 2) +
        Math.pow(field.K - crop.K, 2) +
        Math.pow(field.temperature - crop.temperature, 2) +
        Math.pow(field.humidity - crop.humidity, 2) +
        Math.pow(field.ph - crop.ph, 2) +
        Math.pow(field.rainfall - crop.rainfall, 2)
    );
}

export function getRecommendations(fieldData) {
    const allCrops = loadCropData();
    
    const scoredCrops = allCrops.map(crop => {
        return {
            label: crop.label,
            distance: calculateDistance(fieldData, crop)
        };
    });

    scoredCrops.sort((a, b) => a.distance - b.distance);

    const uniqueRecommendations = [...new Set(scoredCrops.map(c => c.label))];

    return uniqueRecommendations.slice(0, 3);
}