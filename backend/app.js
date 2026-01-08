import express from "express";
import cors from "cors";
import dotenv from "dotenv";
import chatRoutes from "./routes/chat.routes.js";
import irrigationRoutes from "./routes/irrigation.routes.js";
import weatherRoutes from "./routes/weather.routes.js";
import authRoutes from "./routes/auth.routes.js";

dotenv.config();

const app = express();

app.use(cors());
app.use(express.json());
app.use("/", irrigationRoutes);
app.use("/chat", chatRoutes);
app.use("/weather", weatherRoutes);
app.use("/auth", authRoutes);
app.listen(3000, "0.0.0.0", () => {
  console.log("Server running on port 3000");
});
