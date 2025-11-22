// 📄 hiking-backend/routes/users.js
import express from "express";
import multer from "multer";
import cloudinary from "./cloudinary.js";
import User from "../models/User.js";
import SoloTrail from "../models/SoloTrail.js";
import TrailGroup from "../models/TrailGroup.js";

const router = express.Router();

// ✅ Multer setup (memory storage) for direct Cloudinary upload
const storage = multer.memoryStorage();
const upload = multer({ storage });

////////////////////////////////////////////////////////////////////////////////////////////////

// ✅ GET user by ID (for Edit Profile fetch)
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    res.json(user);
  } catch (error) {
    console.error("❌ Fetch user error:", error);
    res.status(500).json({ message: "Server error" });
  }
});

// ✅ UPDATE user profile (with optional image)
router.post("/update", upload.single("profileImage"), async (req, res) => {
  try {
    const { userId, name, email, phone } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // ✅ Build update object
    const updateData = {
      name,
      email,
      phone,
    };

    // ✅ Handle profile image via Cloudinary (do not save locally)
    if (req.file) {
      try {
        const uploadResult = await new Promise((resolve, reject) => {
          const stream = cloudinary.uploader.upload_stream(
            { folder: "profile" },
            (error, result) => {
              if (error) return reject(error);
              resolve(result);
            }
          );
          stream.end(req.file.buffer);
        });

        // Save secure Cloudinary URL in MongoDB
        updateData.profileImage = uploadResult.secure_url;
      } catch (uploadErr) {
        console.error("❌ Cloudinary upload error:", uploadErr);
        return res
          .status(500)
          .json({ message: "Image upload failed", error: uploadErr.message });
      }
    }

    const updatedUser = await User.findByIdAndUpdate(userId, updateData, {
      new: true,
    });

    res.json({
      message: "Profile updated successfully",
      user: updatedUser,
    });
  } catch (error) {
    console.error("❌ Update user error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ✅ Add emergency contact (max 5)
router.post("/emergency-contacts/add", async (req, res) => {
  try {
    const { userId, contact } = req.body;
    if (!userId || !contact) {
      return res.status(400).json({ message: "Missing parameters" });
    }
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    user.emergencyContacts = user.emergencyContacts || [];
    if (user.emergencyContacts.length >= 5) {
      return res.status(400).json({ message: "Maximum 5 emergency contacts" });
    }
    const { name, email, phone } = contact;
    user.emergencyContacts.push({ name: name || "", email: email || "", phone: phone || "", share: false });
    await user.save();
    res.json({ message: "Contact added", emergencyContacts: user.emergencyContacts });
  } catch (error) {
    console.error("❌ Add emergency contact error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ✅ Remove emergency contact by index
router.post("/emergency-contacts/remove", async (req, res) => {
  try {
    const { userId, index } = req.body;
    if (!userId || typeof index !== "number") {
      return res.status(400).json({ message: "Missing parameters" });
    }
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    user.emergencyContacts = user.emergencyContacts || [];
    if (index < 0 || index >= user.emergencyContacts.length) {
      return res.status(400).json({ message: "Invalid index" });
    }
    user.emergencyContacts.splice(index, 1);
    await user.save();
    res.json({ message: "Contact removed", emergencyContacts: user.emergencyContacts });
  } catch (error) {
    console.error("❌ Remove emergency contact error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ✅ Update emergency contact by index
router.post("/emergency-contacts/update", async (req, res) => {
  try {
    const { userId, index, contact } = req.body;
    if (!userId || typeof index !== "number" || !contact) {
      return res.status(400).json({ message: "Missing parameters" });
    }
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    user.emergencyContacts = user.emergencyContacts || [];
    if (index < 0 || index >= user.emergencyContacts.length) {
      return res.status(400).json({ message: "Invalid index" });
    }
    const { name, email, phone } = contact;
    const existing = user.emergencyContacts[index] || {};
    user.emergencyContacts[index] = {
      name: name || "",
      email: email || "",
      phone: phone || "",
      share: existing.share === true,
    };
    await user.save();
    res.json({ message: "Contact updated", emergencyContacts: user.emergencyContacts });
  } catch (error) {
    console.error("❌ Update emergency contact error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

router.post("/emergency-contacts/share-toggle", async (req, res) => {
  try {
    const { userId, index, share } = req.body;
    if (!userId || typeof index !== "number") {
      return res.status(400).json({ message: "Missing parameters" });
    }
    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });
    user.emergencyContacts = user.emergencyContacts || [];
    if (index < 0 || index >= user.emergencyContacts.length) {
      return res.status(400).json({ message: "Invalid index" });
    }
    const value = share === true || share === "true";
    user.emergencyContacts[index].share = value;
    await user.save();
    res.json({ message: "Share preference updated", emergencyContacts: user.emergencyContacts });
  } catch (error) {
    console.error("❌ Share toggle error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ✅ UPDATE toggle settings one by one
router.post("/update-setting", async (req, res) => {
  try {
    const { userId, key, value } = req.body;
    if (!userId || !key) {
      return res.status(400).json({ message: "Missing parameters" });
    }

    // Ensure only valid keys can be updated
    const validKeys = [
      "pushNotifications",
      "locationSharing",
      "fallDetection",
      "autoCheckIn",
      "weatherAlerts",
    ];
    if (!validKeys.includes(key)) {
      return res.status(400).json({ message: "Invalid setting key" });
    }

    const update = {};
    update[`settings.${key}`] = value === true || value === "true";

    const updatedUser = await User.findByIdAndUpdate(userId, update, {
      new: true,
    });

    res.json({
      message: "Setting updated successfully",
      settings: updatedUser.settings,
    });
  } catch (error) {
    console.error("❌ Update setting error:", error);
    res.status(500).json({ message: "Server error", error: error.message });
  }
});

// ✅ Combined hike counts for profile page (solo + group)
router.get("/hike-counts/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ message: "Missing userId" });
    }

    const [soloCount, groupCount] = await Promise.all([
      SoloTrail.countDocuments({ userId, status: "completed" }),
      TrailGroup.countDocuments({
        "members.userId": userId,
        "activeTrail.status": "completed",
      }),
    ]);

    return res.json({
      success: true,
      userId,
      totalSoloHikes: soloCount,
      totalGroupHikes: groupCount,
    });
  } catch (error) {
    console.error("❌ Hike counts error:", error);
    return res
      .status(500)
      .json({ message: "Server error", error: error.message });
  }
});

export default router;
