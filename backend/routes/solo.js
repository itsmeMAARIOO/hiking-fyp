import express from "express";
import SoloTrail from "../models/SoloTrail.js";

const router = express.Router();

// ✅ Count completed solo hikes by user
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
    console.error("❌ Error counting solo hikes:", err);
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
    console.error("❌ Error fetching solo history:", err);
    res.status(500).json({ error: "Server error", details: err.message });
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
    console.error("❌ Error fetching solo trail:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

// ✅ Live location update while solo trail is active
router.post("/update-location", async (req, res) => {
  try {
    const { userId, trailName, latitude, longitude } = req.body;

    if (
      !userId ||
      typeof latitude !== "number" ||
      typeof longitude !== "number"
    ) {
      return res
        .status(400)
        .json({ error: "Missing userId or invalid coordinates" });
    }

    const now = new Date(new Date().getTime() + 8 * 60 * 60 * 1000);

    // Find active solo trail for the user or create one
    let trail = await SoloTrail.findOne({ userId, status: "active" });
    if (!trail) {
      trail = await SoloTrail.create({
        userId,
        trailName: trailName || "Unnamed Trail",
        startTime: now,
        status: "active",
      });
    }

    trail.latestLatitude = latitude;
    trail.latestLongitude = longitude;
    trail.lastUpdated = now;
    await trail.save();

    res.json({ success: true, trail });
  } catch (err) {
    console.error("❌ Error updating solo location:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

// ✅ Complete the current active solo trail (do NOT create a new record)
router.post("/save", async (req, res) => {
  try {
    const { userId, trailName, endTime } = req.body;

    if (!userId || !trailName) {
      return res.status(400).json({ error: "Missing userId or trailName" });
    }

    const now = new Date(new Date().getTime() + 8 * 60 * 60 * 1000);

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

    res.json({ success: true, trail });
  } catch (err) {
    console.error("❌ Error completing solo trail:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

export default router;
