import axios from "axios";

export const analyzeIrrigation = async (lat, lon, crop, lastIrrigatedDays) => {
  const mlServiceUrl = process.env.ML_SERVICE_URL || "http://127.0.0.1:5000";
  const url = `${mlServiceUrl}/irrigation/recommend`;

  const response = await axios.post(url, {
    lat,
    lng: lon,
    crop,
    last_irrigated_days: lastIrrigatedDays,
  });

  return response.data;
};
