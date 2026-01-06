import express from "express";
import CheckIn from "../models/CheckIn.js";

const router = express.Router();

// Create or Update Check-In
router.post("/", async (req, res) => {
  try {
    const { userId, checkinTime, lastCheckinTime, latitude, longitude } = req.body;

    // If userId is missing, stop
    if (!userId) {
      return res.status(400).json({ message: "userId is required" });
    }

    // Find existing check-in and update it
    const updatedCheckIn = await CheckIn.findOneAndUpdate(
      { userId }, // filter by userId
      {
        $set: { checkinTime, lastCheckinTime, latitude, longitude },
      },
      {
        new: true, // return updated document
        upsert: true, // create if not found
      }
    );

    res
      .status(200)
      .json({ message: "Check-in saved or updated!", data: updatedCheckIn });
  } catch (err) {
    console.error("Error saving check-in:", err);
    res.status(500).json({ message: err.message });
  }
});

// Fetch latest check-in by userId
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const latestCheckIn = await CheckIn.findOne({ userId })
      .sort({ checkinTime: -1 })
      .exec();

    if (!latestCheckIn) {
      return res.status(404).json({ message: "No check-in found" });
    }

    res.status(200).json(latestCheckIn);
  } catch (err) {
    console.error("❌ Error fetching check-in:", err);
    res.status(500).json({ message: err.message });
  }
});

export default router;
