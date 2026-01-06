import express from "express";
import bcrypt from "bcryptjs";
import crypto from "crypto";
import nodemailer from "nodemailer";
import User from "../models/User.js";

const router = express.Router();

// Signup
router.post("/signup", async (req, res) => {
  try {
    const {
      name,
      email,
      password,
      dateOfBirth,
      gender,
      weightKg,
      heightCm,
      bloodType,
      allergies,
      phone,
    } = req.body;

    // Check if user exists
    const existingUser = await User.findOne({ email });
    if (existingUser)
      return res.status(400).json({ message: "User already exists" });

    // Hash password
    const hashedPassword = await bcrypt.hash(password, 10);

    // Create new user
    let allergiesArr = [];
    if (Array.isArray(allergies)) {
      allergiesArr = allergies.filter((x) => typeof x === "string");
    } else if (typeof allergies === "string") {
      allergiesArr = allergies
        .split(",")
        .map((s) => s.trim())
        .filter((s) => s.length > 0);
    }

    const newUser = new User({
      name,
      email,
      password: hashedPassword,
      phone,
      dateOfBirth: dateOfBirth ? new Date(dateOfBirth) : undefined,
      gender,
      weightKg,
      heightCm,
      bloodType,
      allergies: allergiesArr,
    });
    await newUser.save();

    res.json({ message: "User created" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

// Login
router.post("/login", async (req, res) => {
  try {
    const { email, password } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) return res.status(404).json({ message: "User not found" });

    // Check password
    const isMatch = await bcrypt.compare(password, user.password);
    if (!isMatch)
      return res.status(401).json({ message: "Invalid credentials" });

    // Return user info including profile image (if any)
    res.json({
      id: user._id,
      name: user.name,
      email: user.email,
      profileImage: user.profileImage || "", 
    });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

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

router.post("/forgot-password", async (req, res) => {
  try {
    const { email } = req.body;
    if (!email) return res.status(400).json({ message: "Email required" });
    const user = await User.findOne({ email });
    if (!user) return res.status(200).json({ message: "If account exists, email sent" });

    const token = crypto.randomBytes(32).toString("hex");
    const expires = new Date(Date.now() + 60 * 60 * 1000);
    user.resetPasswordToken = token;
    user.resetPasswordExpires = expires;
    await user.save();

    const transporter = createTransport();
    const fromEmail =
      process.env.EMAIL_FROM ||
      process.env.SMTP_FROM ||
      process.env.EMAIL_USERNAME ||
      process.env.SMTP_USER;
    const base = `${req.protocol}://${req.get("host")}`;
    const link = `${base}/api/auth/reset/${token}`;

    const html = `
      <div style="font-family: Arial, Helvetica, sans-serif; max-width: 580px; margin:0 auto; border:1px solid #c8e6c9; border-radius:8px; overflow:hidden;">
        <div style="background:#1c3f3f;color:#fff;padding:16px 20px; text-align:center; font-weight:700; font-size:18px; letter-spacing:0.6px;">Reset Your Password</div>
        <div style="padding:20px; color:#1a1a1a; background:#ffffff;">
          <p style="margin:0 0 12px 0; font-size:16px;">We received a request to reset your password.</p>
          <p style="margin:0 0 12px 0; font-size:14px; color:#555;">This link will expire in 1 hour.</p>
          <a href="${link}" style="display:inline-block; background:#6baf89; color:#fff; text-decoration:none; padding:12px 18px; border-radius:6px; font-weight:700; font-size:14px;">Reset Password</a>
          <p style="margin-top:18px; font-size:12px; color:#666;">If the button does not work, copy and paste this link: <br><span style="word-break:break-all;">${link}</span></p>
        </div>
      </div>`;

    if (transporter && fromEmail) {
      try {
        await transporter.sendMail({
          from: fromEmail,
          to: email,
          subject: "TrailGuard Password Reset",
          text: `Reset your password using this link (valid 1 hour): ${link}`,
          html,
        });
      } catch (e) {
        console.error("Reset email error:", e);
      }
    } else {
      console.warn("Email transport not configured; reset link:", link);
    }

    res.json({ message: "If account exists, email sent" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.get("/reset/:token", async (req, res) => {
  try {
    const { token } = req.params;
    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: new Date() },
    });
    if (!user) return res.status(400).send("<h3>Invalid or expired link</h3>");
    const html = `
      <!doctype html>
      <html>
      <head><meta charset="utf-8"><title>Reset Password</title></head>
      <body style="font-family: Arial, sans-serif; background:#F5F5F0; padding:20px;">
        <div style="max-width:520px; margin:40px auto; background:#fff; padding:24px; border-radius:12px; box-shadow:0 8px 24px rgba(0,0,0,0.1)">
          <h2 style="color:#1c3f3f; margin-top:0;">Set a new password</h2>
          <form method="POST" action="/api/auth/reset-password" style="display:flex; flex-direction:column; gap:12px;">
            <input type="hidden" name="token" value="${token}" />
            <label>New Password</label>
            <input type="password" name="password" minlength="6" required style="padding:12px; border:1px solid #ddd; border-radius:8px;"/>
            <button type="submit" style="background:#6baf89; color:#fff; padding:12px; border:none; border-radius:8px; font-weight:700;">Reset Password</button>
          </form>
        </div>
      </body>
      </html>`;
    res.setHeader("Content-Type", "text/html; charset=utf-8");
    res.send(html);
  } catch (err) {
    res.status(500).send("Server error");
  }
});

// Google Login
router.post("/google", async (req, res) => {
  try {
    const { idToken } = req.body;
    
    // Verify token with Google
    const response = await fetch(`https://oauth2.googleapis.com/tokeninfo?id_token=${idToken}`);
    const data = await response.json();

    if (data.error || !data.email) {
      return res.status(400).json({ message: "Invalid Google Token" });
    }

    const { email, name, picture } = data;

    // Check if user exists
    let user = await User.findOne({ email });

    if (user) {
      // User exists - Return success with token
      res.json({
        token: "google-session-token", // Mock token since JWT is not fully implemented in this file yet
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          profileImage: user.profileImage || picture,
        },
      });
    } else {
      // User does not exist - Return 200 but without token so frontend redirects to Signup
      res.json({
        message: "User not found, please sign up",
        email: email,
        name: name
      });
    }
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

router.post("/reset-password", async (req, res) => {
  try {
    const { token, password } = req.body;
    if (!token || !password)
      return res.status(400).json({ message: "Token and password required" });
    const user = await User.findOne({
      resetPasswordToken: token,
      resetPasswordExpires: { $gt: new Date() },
    });
    if (!user) return res.status(400).json({ message: "Invalid or expired token" });
    const hashed = await bcrypt.hash(password, 10);
    user.password = hashed;
    user.resetPasswordToken = undefined;
    user.resetPasswordExpires = undefined;
    await user.save();
    res.json({ message: "Password updated" });
  } catch (err) {
    res.status(500).json({ message: err.message });
  }
});

export default router;
