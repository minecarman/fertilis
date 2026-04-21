import axios from "axios";

export const predictYield = async (payload) => {
  const mlServiceUrl = process.env.ML_SERVICE_URL || "http://127.0.0.1:5000";
  const response = await axios.post(`${mlServiceUrl}/yield/predict`, payload);
  return response.data;
};
