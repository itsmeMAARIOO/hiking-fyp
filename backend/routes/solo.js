import express from "express";
import nodemailer from "nodemailer";
import SoloTrail from "../models/SoloTrail.js";
import User from "../models/User.js";

const router = express.Router();

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

// Count completed solo hikes by user
router.get("/count/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ error: "Missing userId" });
    }

    const count = await SoloTrail.countDocuments({
      userId,
      status: "completed",
    });
    res.json({ success: true, userId, totalSoloHikes: count });
  } catch (err) {
    console.error("Error counting solo hikes:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

router.get("/history/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ error: "Missing userId" });
    }
    const trails = await SoloTrail.find({ userId, status: "completed" })
      .sort({ endTime: -1, updatedAt: -1 })
      .lean();
    res.json({ success: true, trails });
  } catch (err) {
    console.error("Error fetching solo history:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

// Remove a completed solo hike from history by trailId
router.delete("/history/:trailId", async (req, res) => {
  try {
    const { trailId } = req.params;
    if (!trailId) {
      return res.status(400).json({ error: "Missing trailId" });
    }

    const trail = await SoloTrail.findById(trailId);
    if (!trail) {
      return res.status(404).json({ error: "Solo trail not found" });
    }

    if (trail.status !== "completed") {
      return res
        .status(400)
        .json({ error: "Only completed trails can be removed from history" });
    }

    await SoloTrail.deleteOne({ _id: trailId });
    return res.json({ success: true });
  } catch (err) {
    console.error("Error deleting solo history:", err);
    return res
      .status(500)
      .json({ error: "Server error", details: err.message });
  }
});

router.get("/trail/:trailId", async (req, res) => {
  try {
    const { trailId } = req.params;
    const trail = await SoloTrail.findById(trailId).lean();
    if (!trail) {
      return res.status(404).json({ error: "Solo trail not found" });
    }
    res.json({ success: true, trail });
  } catch (err) {
    console.error("Error fetching solo trail:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

// Live location update while solo trail is active
router.post("/update-location", async (req, res) => {
  try {
    const { userId, trailName, trailDescription, latitude, longitude } =
      req.body;

    if (
      !userId ||
      typeof latitude !== "number" ||
      typeof longitude !== "number"
    ) {
      return res
        .status(400)
        .json({ error: "Missing userId or invalid coordinates" });
    }

    const now = new Date();

    // Find active solo trail for the user or create one
    let trail = await SoloTrail.findOne({ userId, status: "active" });
    if (!trail) {
      trail = await SoloTrail.create({
        userId,
        trailName: trailName || "Unnamed Trail",
        trailDescription: trailDescription || "",
        startTime: now,
        status: "active",
      });
    } else {
      // Update description if provided, even if trail exists
      if (trailDescription !== undefined) {
        trail.trailDescription = trailDescription;
      }
    }

    trail.latestLatitude = latitude;
    trail.latestLongitude = longitude;
    trail.lastUpdated = now;
    await trail.save();

    res.json({ success: true, trail });
  } catch (err) {
    console.error("Error updating solo location:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

// Complete the current active solo trail (do NOT create a new record)
router.post("/save", async (req, res) => {
  try {
    const { userId, trailName, endTime } = req.body;

    if (!userId || !trailName) {
      return res.status(400).json({ error: "Missing userId or trailName" });
    }

    const now = new Date();

    // Find the user's currently active solo trail and mark it completed
    // We intentionally only look for one active trail per user
    const trail = await SoloTrail.findOne({ userId, status: "active" });

    if (!trail) {
      // No active trail to complete; don't create duplicates
      return res.status(404).json({
        error: "No active solo trail found to complete",
      });
    }

    trail.status = "completed";
    trail.endTime = endTime || now;
    trail.lastUpdated = now;
    await trail.save();
    try {
      const cancelFn = req.app.get("cancelOverdueCheck");
      if (typeof cancelFn === "function") {
        cancelFn(trail._id);
      }
    } catch (_) {}

    res.json({ success: true, trail });
  } catch (err) {
    console.error("Error completing solo trail:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

// Notify contacts that a solo trail has started (green template)
router.post("/notify/start", async (req, res) => {
  try {
    const {
      userId,
      contacts,
      latitude,
      longitude,
      trailName,
      trailDescription,
      timestamp,
      expectedEndTime,
    } = req.body;
    if (
      !userId ||
      !Array.isArray(contacts) ||
      typeof latitude !== "number" ||
      typeof longitude !== "number"
    ) {
      return res.status(400).json({ message: "Missing parameters" });
    }

    const when = new Date();
    const expectedEnd = expectedEndTime ? new Date(expectedEndTime) : null;
    const googleMapsUrl = `https://www.google.com/maps?q=${latitude},${longitude}`;
    const timeMY = formatMalaysiaTime(when);
    const expectedMY = expectedEnd ? formatMalaysiaTime(expectedEnd) : null;

    const transporter = createTransport();
    let emailSent = false;
    let emailError = null;
    let replyTo = undefined;
    let senderName = "Hiker";
    try {
      const u = await User.findById(userId).lean();
      if (u && u.email) replyTo = u.email;
      if (u && u.name) senderName = u.name;
    } catch (_) {}
    const fromEmail =
      process.env.EMAIL_FROM ||
      process.env.SMTP_FROM ||
      process.env.EMAIL_USERNAME ||
      process.env.SMTP_USER;

    const subject = `Solo Hike Started${trailName ? `: ${trailName}` : ""}`;

    const headerColor = "#1b5e20"; // dark green
    const accentColor = "#2e7d32"; // green
    const borderColor = "#81c784"; // light green

    const htmlTemplate = (name) => `
      <div style="font-family: Arial, Helvetica, sans-serif; max-width: 580px; margin:0 auto; border:1px solid ${borderColor}; border-radius:8px; overflow:hidden;">
        <div style="background:${headerColor};color:#fff;padding:16px 20px; text-align:center; font-weight:700; font-size:18px; letter-spacing:0.6px;">
          Solo Hike Started
        </div>
        <div style="padding:20px; color:#1a1a1a; background:#ffffff;">
          <p style="margin:0 0 12px 0; font-size:16px;">
            ${senderName}${
      trailName ? ` has started "${trailName}"` : " has started a solo hike"
    } and shared their current location.
          </p>
          <div style="margin:16px 0; padding:12px; border:1px dashed ${borderColor}; border-radius:6px; background:#f1f8e9;">
            <div style="font-size:14px; color:${accentColor}; font-weight:700;">Current Coordinates</div>
            <div style="font-size:15px;"><strong>Lat:</strong> ${latitude} &nbsp; <strong>Lng:</strong> ${longitude}</div>
            <div style="font-size:13px; color:#555; margin-top:6px;">Time (MYT): ${timeMY}</div>
          </div>
          ${
            expectedMY
              ? `
          <div style="margin:16px 0; padding:12px; border:1px dashed ${borderColor}; border-radius:6px; background:#fffde7;">
            <div style="font-size:14px; color:#8d6e63; font-weight:700;">Expected End Time</div>
            <div style="font-size:13px; color:#555;">${expectedMY}</div>
          </div>
          `
              : ""
          }
           ${
             trailDescription
               ? `
           <div style="margin:16px 0; padding:12px; border:1px dashed ${borderColor}; border-radius:6px; background:#e0f2f1;">
             <div style="font-size:14px; color:#00695c; font-weight:700;">Trail Description</div>
             <div style="font-size:13px; color:#555;">${trailDescription}</div>
           </div>
           `
               : ""
           }
          <p style="margin:0 0 14px 0; font-size:15px;">Use the button below to open the location in Google Maps.</p>
          <a href="${googleMapsUrl}" style="display:inline-block; background:${accentColor}; color:#fff; text-decoration:none; padding:12px 18px; border-radius:6px; font-weight:700; font-size:14px;">Open in Google Maps</a>
          <p style="margin-top:18px; font-size:12px; color:#666;">If the button does not work, copy and paste this link: <br><span style="word-break:break-all;">${googleMapsUrl}</span></p>
        </div>
      </div>
    `;

    if (transporter) {
      try {
        const mailPromises = contacts
          .filter((c) => c.email)
          .map((c) =>
            transporter.sendMail({
              from: fromEmail,
              to: c.email,
              replyTo,
              subject,
              text: `${senderName} started a solo hike${
                trailName ? `: ${trailName}` : ""
              } and shared their location.\nLat: ${latitude}, Lng: ${longitude}\nTime (MYT): ${timeMY}${
                expectedMY ? `\nExpected End (MYT): ${expectedMY}` : ""
              }${
                trailDescription
                  ? `\nDescription: ${trailDescription}`
                  : ""
              }\nGoogle Maps: ${googleMapsUrl}`,
              html: htmlTemplate(c.name || ""),
            })
          );
        await Promise.all(mailPromises);
        emailSent = true;
      } catch (e) {
        console.error("❌ Email send error:", e);
        emailError = (e && e.message) || "Email send failed";
      }
    }
    try {
      let trail = await SoloTrail.findOne({ userId, status: "active" });
      if (!trail) {
        trail = await SoloTrail.create({
          userId,
          trailName: trailName || "Unnamed Trail",
          trailDescription: trailDescription || "",
          startTime: when,
          status: "active",
        });
      } else {
        if (trailDescription !== undefined) {
            trail.trailDescription = trailDescription;
        }
      }
      trail.latestLatitude = latitude;
      trail.latestLongitude = longitude;
      trail.lastUpdated = when;
      if (expectedEnd) trail.expectedEndTime = expectedEnd;
      if (Array.isArray(contacts)) {
        trail.notifiedContacts = contacts
          .filter((c) => c && c.email)
          .map((c) => ({ name: c.name || "", email: c.email }));
      }
      await trail.save();
      try {
        const scheduleFn = req.app.get("scheduleOverdueCheck");
        if (typeof scheduleFn === "function" && trail.expectedEndTime) {
          scheduleFn(trail._id, trail.expectedEndTime);
        }
      } catch (_) {}
    } catch (_) {}

    return res.json({ googleMapsUrl, emailSent, emailError });
  } catch (err) {
    return res
      .status(500)
      .json({ message: "Failed to send start notification" });
  }
});

export default router;
