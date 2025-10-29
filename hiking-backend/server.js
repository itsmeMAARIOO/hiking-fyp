import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes/auth.js";
import checkinRoutes from "./routes/checkin.js";
import userRoutes from "./routes/user_temp.js";
import groupRoutes from "./routes/group.js";
import soloRoutes from "./routes/solo.js";
import offlineMapRoutes from "./routes/offlineMap.js";
import path from "path";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Middleware first
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// ✅ Serve uploaded files (must come before routes if serving images)
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

// ✅ Serve offline map tiles
app.use("/offline-maps", express.static(path.join(process.cwd(), "offline-maps")));

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/checkin", checkinRoutes);
app.use("/api/users", userRoutes);
app.use("/api/group", groupRoutes);
app.use("/api/solo", soloRoutes);
app.use("/api", offlineMapRoutes);

// MongoDB connection
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB connected"))
  .catch((err) => console.error("MongoDB connection error:", err));

// Start server
const PORT = process.env.PORT || 3000;
app.listen(PORT, "0.0.0.0", () =>
  console.log(`🚀 Server running on http://0.0.0.0:${PORT}`)
);
