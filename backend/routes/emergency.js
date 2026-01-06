import express from "express";
import nodemailer from "nodemailer";
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
  const months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
  const dd = String(t.getUTCDate()).padStart(2, "0");
  const mmm = months[t.getUTCMonth()];
  const yyyy = t.getUTCFullYear();
  const hh = String(t.getUTCHours()).padStart(2, "0");
  const mm = String(t.getUTCMinutes()).padStart(2, "0");
  const ss = String(t.getUTCSeconds()).padStart(2, "0");
  return `${dd}-${mmm}-${yyyy} ${hh}:${mm}:${ss} MYT`;
}

router.post("/share/start", async (req, res) => {
  try {
    const { userId, contacts, latitude, longitude, timestamp } = req.body;
    if (!userId || !Array.isArray(contacts) || typeof latitude !== "number" || typeof longitude !== "number") {
      return res.status(400).json({ message: "Missing parameters" });
    }

    const when = timestamp ? new Date(timestamp) : new Date();
    const googleMapsUrl = `https://www.google.com/maps?q=${latitude},${longitude}`;
    const timeMY = formatMalaysiaTime(when);

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
    const fromEmail = process.env.EMAIL_FROM || process.env.SMTP_FROM || process.env.EMAIL_USERNAME || process.env.SMTP_USER;
    if (transporter) {
      try {
        const mailPromises = contacts
          .filter((c) => c.email)
          .map((c) =>
            transporter.sendMail({
              from: fromEmail,
              to: c.email,
              replyTo,
              subject: "EMERGENCY ALERT",
              text: `EMERGENCY ALERT\n${senderName} triggered an emergency and shared their location.\nLat: ${latitude}, Lng: ${longitude}\nTime (MYT): ${timeMY}\nGoogle Maps: ${googleMapsUrl}`,
              html: `<div style="font-family: Arial, Helvetica, sans-serif; max-width: 580px; margin:0 auto; border:1px solid #e53935; border-radius:8px; overflow:hidden;"><div style="background:#b71c1c;color:#fff;padding:16px 20px; text-align:center; font-weight:700; font-size:18px; letter-spacing:0.6px;">EMERGENCY ALERT</div><div style="padding:20px; color:#222; background:#fff;"><p style="margin:0 0 12px 0; font-size:16px;">${senderName} triggered an emergency and shared their current location.</p><div style="margin:16px 0; padding:12px; border:1px dashed #e53935; border-radius:6px; background:#fff5f5;"><div style="font-size:14px; color:#b71c1c; font-weight:700;">Current Coordinates</div><div style="font-size:15px;"><strong>Lat:</strong> ${latitude} &nbsp; <strong>Lng:</strong> ${longitude}</div><div style="font-size:13px; color:#555; margin-top:6px;">Time (MYT): ${timeMY}</div></div><p style="margin:0 0 14px 0; font-size:15px;">Use the button below to open the location in Google Maps.</p><a href="${googleMapsUrl}" style="display:inline-block; background:#e53935; color:#fff; text-decoration:none; padding:12px 18px; border-radius:6px; font-weight:700; font-size:14px;">Open in Google Maps</a><p style="margin-top:18px; font-size:12px; color:#666;">If the button does not work, copy and paste this link: <br><span style="word-break:break-all;">${googleMapsUrl}</span></p></div></div>`,
            })
          );
        await Promise.all(mailPromises);
        emailSent = true;
      } catch (e) {
        console.error("Email send error:", e);
        emailError = (e && e.message) || "Email send failed";
      }
    }

    return res.json({ googleMapsUrl, emailSent, emailError });
  } catch (err) {
    return res.status(500).json({ message: "Failed to start location sharing" });
  }
});


export default router;