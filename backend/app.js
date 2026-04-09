import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import chatRoutes from "./routes/chat.routes.js";
import irrigationRoutes from "./routes/irrigation.routes.js";
import weatherRoutes from "./routes/weather.routes.js";
import authRoutes from "./routes/auth.routes.js";
import fieldRoutes from "./routes/field.routes.js";
import recommendationRoutes from './routes/recommendation.routes.js';
import errorHandler from "./middlewares/errorHandler.js";

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());

// API v1 Routes
app.use("/api/v1/irrigation", irrigationRoutes);
app.use("/api/v1/chat", chatRoutes);
app.use("/api/v1/weather", weatherRoutes);
app.use("/api/v1/auth", authRoutes);
app.use("/api/v1/fields", fieldRoutes);
app.use("/api/v1/recommendations", recommendationRoutes);

app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// Global Error Handler Middleware
app.use(errorHandler);

const port = process.env.PORT || 3000;

app.listen(port, "0.0.0.0", () => {
  console.log(`Server running on port ${port}`);
});
