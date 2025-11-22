import express from "express";
import mongoose from "mongoose";
import cors from "cors";
import dotenv from "dotenv";
import authRoutes from "./routes/auth.js";
import checkinRoutes from "./routes/checkin.js";
import userRoutes from "./routes/user_temp.js";
import groupRoutes from "./routes/group.js";
import soloRoutes from "./routes/solo.js";
import chatRoutes from "./routes/chat.js";
import emergencyRoutes from "./routes/emergency.js";
import savedTrailsRoutes from "./routes/saved_trail.js";
import path from "path";
import http from "http";
import { Server as SocketIOServer } from "socket.io";

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
app.use(
  "/offline-maps",
  express.static(path.join(process.cwd(), "offline-maps"))
);

// ✅ Routes
app.use("/api/auth", authRoutes);
app.use("/api/checkin", checkinRoutes);
app.use("/api/users", userRoutes);
app.use("/api/group", groupRoutes);
app.use("/api/solo", soloRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/emergency", emergencyRoutes);
app.use("/api/saved-trails", savedTrailsRoutes);

// MongoDB connection
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("✅ MongoDB connected"))
  .catch((err) => console.error("MongoDB connection error:", err));

// Start server with Socket.IO
const PORT = process.env.PORT || 3000;
const server = http.createServer(app);
const io = new SocketIOServer(server, {
  cors: {
    origin: "*",
    methods: ["GET", "POST"],
  },
});

// attach io to app for access in routes
app.set("io", io);

io.on("connection", (socket) => {
  console.log("🔌 Client connected:", socket.id);
  socket.on("join", ({ groupId }) => {
    if (groupId) {
      socket.join(groupId);
      console.log(`👥 Socket ${socket.id} joined room ${groupId}`);
    }
  });
  socket.on("disconnect", () => {
    console.log("📴 Client disconnected:", socket.id);
  });
});

server.listen(PORT, "0.0.0.0", () =>
  console.log(`🚀 Server with Socket.IO running on http://0.0.0.0:${PORT}`)
);
