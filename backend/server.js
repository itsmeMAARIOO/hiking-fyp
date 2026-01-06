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
import firstAidRoutes from "./routes/first_aid.js";
import path from "path";
import http from "http";
import { Server as SocketIOServer } from "socket.io";
import nodemailer from "nodemailer";
import SoloTrail from "./models/SoloTrail.js";
import User from "./models/User.js";
import ChatMessage from "./models/ChatMessage.js";

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json());

// Middleware first
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Serve uploaded files (must come before routes if serving images)
app.use("/uploads", express.static(path.join(process.cwd(), "uploads")));

// Serve offline map tiles
app.use(
  "/offline-maps",
  express.static(path.join(process.cwd(), "offline-maps"))
);

// Routes
app.use("/api/auth", authRoutes);
app.use("/api/checkin", checkinRoutes);
app.use("/api/users", userRoutes);
app.use("/api/group", groupRoutes);
app.use("/api/solo", soloRoutes);
app.use("/api/chat", chatRoutes);
app.use("/api/emergency", emergencyRoutes);
app.use("/api/saved-trails", savedTrailsRoutes);
app.use("/api/first-aid", firstAidRoutes);

// MongoDB connection
mongoose
  .connect(process.env.MONGO_URI)
  .then(() => console.log("MongoDB connected"))
  .catch((err) => console.error("MongoDB connection error:", err));

// server.js
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
  socket.on("join", ({ groupId }) => {
    if (groupId) {
      socket.join(groupId);
    }
  });

  socket.on("chat:seen", async (data) => {
    try {
      const { groupId, messageId, userId } = data;
      // Broadcast to others in the room
      socket.to(groupId).emit("chat:seen", data);

      // Update Persistence
      if (messageId && userId) {
        await ChatMessage.updateOne(
          { _id: messageId, "seenBy.userId": { $ne: userId } },
          { $push: { seenBy: { userId, seenAt: new Date() } } }
        );
      }
    } catch (e) {
      console.error("Error handling chat:seen:", e);
    }
  });

  socket.on("group:time_update", (data) => {
    try {
      const { groupId, seconds } = data;
      if (groupId && seconds !== undefined) {
        // Broadcast time to everyone else in the group
        socket.to(groupId).emit("group:time_update", { seconds });
      }
    } catch (e) {
      console.error("Error handling group:time_update:", e);
    }
  });

  socket.on("disconnect", () => {
    console.log("Client disconnected:", socket.id);
  });
});

server.listen(PORT, "0.0.0.0", () =>
  console.log(`Server with Socket.IO running on http://0.0.0.0:${PORT}`)
);

function createTransport() {
  const user = process.env.EMAIL_USERNAME || process.env.SMTP_USER;
  const pass = process.env.EMAIL_PASSWORD || process.env.SMTP_PASS;
  const service = process.env.EMAIL_SERVICE || process.env.SMTP_SERVICE;
  if ((service && /gmail/i.test(service)) || /@gmail\.com$/i.test(user || "")) {
    if (!user || !pass) return null;
    return nodemailer.createTransport({
      service: "gmail",
      auth: { user, pass },
      tls: { minVersion: "TLSv1.2" },
    });
  }
  const host = process.env.EMAIL_HOST || process.env.SMTP_HOST;
  const port = Number(process.env.EMAIL_PORT || process.env.SMTP_PORT || 0);
  if (!host || !port || !user || !pass) return null;
  return nodemailer.createTransport({
    host,
    port,
    secure: port === 465,
    auth: { user, pass },
    requireTLS: port === 587,
    tls: { minVersion: "TLSv1.2" },
  });
}

function formatMalaysiaTime(date) {
  const t = new Date(date.getTime() + 8 * 60 * 60 * 1000);
  const months = [
    "Jan",
    "Feb",
    "Mar",
    "Apr",
    "May",
    "Jun",
    "Jul",
    "Aug",
    "Sep",
    "Oct",
    "Nov",
    "Dec",
  ];
  const dd = String(t.getUTCDate()).padStart(2, "0");
  const mmm = months[t.getUTCMonth()];
  const yyyy = t.getUTCFullYear();
  const hh = String(t.getUTCHours()).padStart(2, "0");
  const mm = String(t.getUTCMinutes()).padStart(2, "0");
  const ss = String(t.getUTCSeconds()).padStart(2, "0");
  return `${dd}-${mmm}-${yyyy} ${hh}:${mm}:${ss} MYT`;
}

const scheduledTimers = new Map();

async function sendOverdueEmailAndMark(trailId) {
  try {
    const t = await SoloTrail.findById(trailId).lean();
    if (!t || t.status !== "active" || t.overdueNotified) return;
    const transporter = createTransport();
    const fromEmail =
      process.env.EMAIL_FROM ||
      process.env.SMTP_FROM ||
      process.env.EMAIL_USERNAME ||
      process.env.SMTP_USER;
    const replyToUser = await User.findById(t.userId)
      .lean()
      .catch(() => null);
    const replyTo = replyToUser?.email;
    const senderName = replyToUser?.name || "Hiker";
    const endMY = formatMalaysiaTime(new Date(t.expectedEndTime));
    const lastMY = t.lastUpdated
      ? formatMalaysiaTime(new Date(t.lastUpdated))
      : "-";
    const subject = `Solo Hike Overdue${t.trailName ? `: ${t.trailName}` : ""}`;
    const googleMapsUrl =
      t.latestLatitude != null && t.latestLongitude != null
        ? `https://www.google.com/maps?q=${t.latestLatitude},${t.latestLongitude}`
        : null;
    const borderColor = "#ef9a9a";
    const headerColor = "#b71c1c";
    const accentColor = "#d32f2f";
    const html = `
      <div style="font-family: Arial, Helvetica, sans-serif; max-width: 580px; margin:0 auto; border:1px solid ${borderColor}; border-radius:8px; overflow:hidden;">
        <div style="background:${headerColor};color:#fff;padding:16px 20px; text-align:center; font-weight:700; font-size:18px; letter-spacing:0.6px;">Solo Hike Overdue</div>
        <div style="padding:20px; color:#1a1a1a; background:#ffffff;">
          <p style="margin:0 0 12px 0; font-size:16px;">
            ${senderName}${
      t.trailName
        ? ` was expected to finish "${t.trailName}"`
        : " was expected to finish the solo hike"
    } by <strong>${endMY}</strong>.
          </p>
          <div style="margin:16px 0; padding:12px; border:1px dashed ${borderColor}; border-radius:6px; background:#ffebee;">
            <div style="font-size:14px; color:${accentColor}; font-weight:700;">Last Known Location</div>
            <div style="font-size:15px;">${t.latestLatitude ?? "-"} , ${
      t.latestLongitude ?? "-"
    }</div>
            <div style="font-size:13px; color:#555; margin-top:6px;">Last update (MYT): ${lastMY}</div>
          </div>
          ${
            googleMapsUrl
              ? `<a href="${googleMapsUrl}" style="display:inline-block; background:${accentColor}; color:#fff; text-decoration:none; padding:12px 18px; border-radius:6px; font-weight:700; font-size:14px;">Open in Google Maps</a>`
              : ""
          }
          ${
            googleMapsUrl
              ? `<p style="margin-top:18px; font-size:12px; color:#666;">If the button does not work, copy and paste this link: <br><span style="word-break:break-all;">${googleMapsUrl}</span></p>`
              : ""
          }
        </div>
      </div>`;
    const recipients = (t.notifiedContacts || [])
      .filter((c) => c.email)
      .map((c) => c.email);
    if (recipients.length && transporter) {
      try {
        await transporter.sendMail({
          from: fromEmail,
          to: recipients,
          replyTo,
          subject,
          text: `${senderName} may be overdue. Expected end (MYT): ${endMY}. Last known: ${
            t.latestLatitude ?? "-"
          }, ${t.latestLongitude ?? "-"}. Last update (MYT): ${lastMY}${
            googleMapsUrl ? `\nGoogle Maps: ${googleMapsUrl}` : ""
          }`,
          html,
        });
      } catch (e) {
        console.error("Overdue email error:", e);
      }
    }
  } catch (e) {
    console.error("Send overdue error:", e);
  } finally {
    try {
      await SoloTrail.updateOne(
        { _id: trailId },
        { $set: { overdueNotified: true } }
      );
    } catch (_) {}
    const timer = scheduledTimers.get(trailId.toString());
    if (timer) {
      clearTimeout(timer);
      scheduledTimers.delete(trailId.toString());
    }
  }
}

function scheduleOverdueCheck(trailId, expectedEndTime) {
  if (!trailId || !expectedEndTime) return;
  const key = trailId.toString();
  const existing = scheduledTimers.get(key);
  if (existing) {
    clearTimeout(existing);
    scheduledTimers.delete(key);
  }
  const dbDate = new Date(expectedEndTime);
  // subtract 8 hours to get the actual UTC time for comparison with server 'Now'.
  const end = new Date(dbDate.getTime() - 8 * 60 * 60 * 1000);
  
  const now = Date.now();
  const delay = end.getTime() - now;

  if (delay <= 0) {
    sendOverdueEmailAndMark(trailId);
    return;
  }
  const timer = setTimeout(() => sendOverdueEmailAndMark(trailId), delay);
  scheduledTimers.set(key, timer);
}

function cancelOverdueCheck(trailId) {
  const key = trailId?.toString();
  if (!key) return;
  const t = scheduledTimers.get(key);
  if (t) {
    clearTimeout(t);
    scheduledTimers.delete(key);
  }
}

app.set("scheduleOverdueCheck", scheduleOverdueCheck);
app.set("cancelOverdueCheck", cancelOverdueCheck);

(async function bootstrapSchedules() {
  try {
    const active = await SoloTrail.find({
      status: "active",
      overdueNotified: false,
      expectedEndTime: { $ne: null },
    }).lean();
    for (const t of active) {
      scheduleOverdueCheck(t._id, t.expectedEndTime);
    }
  } catch (e) {
    console.error("Bootstrap schedules error:", e);
  }
})();
