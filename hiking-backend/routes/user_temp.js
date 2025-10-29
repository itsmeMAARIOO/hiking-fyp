// // 📄 hiking-backend/routes/users.js
// import express from "express";
// import multer from "multer";
// import path from "path";
// import fs from "fs";
// import User from "../models/User.js";

// const router = express.Router();

// // ✅ Create upload folder if not exist
// const uploadDir = "uploads/profile";
// if (!fs.existsSync(uploadDir)) {
//   fs.mkdirSync(uploadDir, { recursive: true });
// }

// // ✅ Multer setup for profile image upload
// const storage = multer.diskStorage({
//   destination: (req, file, cb) => {
//     cb(null, uploadDir);
//   },
//   filename: (req, file, cb) => {
//     const ext = path.extname(file.originalname);
//     cb(null, `${Date.now()}-${file.fieldname}${ext}`);
//   },
// });
// const upload = multer({ storage });

// ////////////////////////////////////////////////////////////////////////////////////////////////

// // ✅ GET user by ID (for Edit Profile fetch)
// router.get("/:userId", async (req, res) => {
//   try {
//     const { userId } = req.params;
//     const user = await User.findById(userId);
//     if (!user) return res.status(404).json({ message: "User not found" });
//     res.json(user);
//   } catch (error) {
//     console.error("❌ Fetch user error:", error);
//     res.status(500).json({ message: "Server error" });
//   }
// });

// // ✅ UPDATE user profile (with optional image)
// router.post("/update", upload.single("profileImage"), async (req, res) => {
//   try {
//     const { userId, name, email, phone, emergencyName, emergencyPhone } =
//       req.body;

//     const user = await User.findById(userId);
//     if (!user) return res.status(404).json({ message: "User not found" });

//     // ✅ Build update object
//     const updateData = {
//       name,
//       email,
//       phone,
//       emergencyContact: {
//         name: emergencyName,
//         phone: emergencyPhone,
//       },
//     };

//     // ✅ Handle profile image
//     if (req.file) {
//       const baseUrl = `${req.protocol}://${req.get("host")}`;

//       updateData.profileImage = `${baseUrl}/uploads/profile/${req.file.filename}`;
//     }

//     const updatedUser = await User.findByIdAndUpdate(userId, updateData, {
//       new: true,
//     });

//     res.json({
//       message: "Profile updated successfully",
//       user: updatedUser,
//     });
//   } catch (error) {
//     console.error("❌ Update user error:", error);
//     res.status(500).json({ message: "Server error", error: error.message });
//   }
// });

// // ✅ UPDATE toggle settings one by one as needed
// router.post("/update-setting", async (req, res) => {
//   try {
//     const { userId, key, value } = req.body;
//     if (!userId || !key) {
//       return res.status(400).json({ message: "Missing parameters" });
//     }

//     // Ensure only valid keys can be updated
//     const validKeys = [
//       "pushNotifications",
//       "locationSharing",
//       "fallDetection",
//       "autoCheckIn",
//       "weatherAlerts",
//     ];
//     if (!validKeys.includes(key)) {
//       return res.status(400).json({ message: "Invalid setting key" });
//     }

//     const update = {};
//     update[`settings.${key}`] = value === true || value === "true";

//     const updatedUser = await User.findByIdAndUpdate(userId, update, {
//       new: true,
//     });

//     res.json({
//       message: "Setting updated successfully",
//       settings: updatedUser.settings,
//     });
//   } catch (error) {
//     console.error("❌ Update setting error:", error);
//     res.status(500).json({ message: "Server error", error: error.message });
//   }
// });

// export default router;

// 📄 hiking-backend/routes/users.js
import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import User from "../models/User.js";
import SoloTrail from "../models/SoloTrail.js";
import TrailGroup from "../models/TrailGroup.js";

const router = express.Router();

// ✅ Create upload folder if not exist
const uploadDir = "uploads/profile";
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

// ✅ Multer setup for profile image upload
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    cb(null, `${Date.now()}-${file.fieldname}${ext}`);
  },
});
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
    const { userId, name, email, phone, emergencyContact } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ message: "User not found" });

    // ✅ Parse emergencyContact if it's a JSON string
    let parsedEmergencyContact;
    if (typeof emergencyContact === "string") {
      try {
        parsedEmergencyContact = JSON.parse(emergencyContact);
      } catch (e) {
        return res
          .status(400)
          .json({ message: "Invalid emergencyContact format" });
      }
    } else {
      parsedEmergencyContact = emergencyContact;
    }

    // ✅ Build update object
    const updateData = {
      name,
      email,
      phone,
      emergencyContact: parsedEmergencyContact,
    };

    // ✅ Handle profile image
    if (req.file) {
      const baseUrl = `${req.protocol}://${req.get("host")}`;
      updateData.profileImage = `${baseUrl}/uploads/profile/${req.file.filename}`;
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
      TrailGroup.countDocuments({ "members.userId": userId, "activeTrail.status": "completed" }),
    ]);

    return res.json({
      success: true,
      userId,
      totalSoloHikes: soloCount,
      totalGroupHikes: groupCount,
    });
  } catch (error) {
    console.error("❌ Hike counts error:", error);
    return res.status(500).json({ message: "Server error", error: error.message });
  }
});

export default router;
