/**
 * Irrigation Service Layer
 * 
 * Acts as the bridge between the Node.js Express backend and the Python FastAPI ML microservice.
 */
import axios from "axios";

/**
 * Sends geographical and crop data to the ML engine to calculate the FAO-56 irrigation requirement.
 * 
 * @param {number} lat - Latitude of the field
 * @param {number} lon - Longitude of the field (named 'lon' from the Flutter app)
 * @param {string} crop - Name of the crop (e.g. 'tomato')
 * @param {number} lastIrrigatedDays - Days since last irrigation
 * @returns {Promise<Object>} The ML engine's irrigation recommendation JSON
 */
export const analyzeIrrigation = async (lat, lon, crop, lastIrrigatedDays) => {
  // Use environment variable for ML service or fallback to localhost port 5000
  const mlServiceUrl = process.env.ML_SERVICE_URL || "http://127.0.0.1:5000";
  const url = `${mlServiceUrl}/irrigation/recommend`;

  // POST request to the Python ML microservice.
  // Note the crucial parameter mapping here:
  // The Flutter frontend uses 'lon', but the Python ML model explicitly expects 'lng'.
  const response = await axios.post(url, {
    lat: lat,
    lng: lon,  // MAPPING: lon -> lng to resolve the routing mismatch between Flutter and Python
    crop: crop,
    last_irrigated_days: lastIrrigatedDays,
  });

  return response.data;
};
