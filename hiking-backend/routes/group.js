import express from "express";
import mongoose from "mongoose";
import TrailGroup from "../models/TrailGroup.js";
import TrailHistory from "../models/TrailHistory.js";
import Checkin from "../models/Checkin.js";
const router = express.Router();

/* ---------------------------------------------
 🚀 API Routes
----------------------------------------------*/

//--------------------------------------------------------------------------------- Using API -----------------------------------------------------------------------------
// ✅ Get nearby hikers
router.post("/nearby", async (req, res) => {
  try {
    const { latitude, longitude, radius = 1.5, excludeUserId } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({ error: "Missing coordinates" });
    }

    // ⏰ 5-minute window
    const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);

    // 🧭 Fetch check-ins within the last 5 minutes & populate user info
    const recentCheckins = await Checkin.find({
      checkinTime: { $gte: fiveMinutesAgo },
    }).populate("userId", "name profileImage"); // ✅ populate name + optional profileImage

    const toRad = (val) => (val * Math.PI) / 180;
    const R = 6371; // Earth radius in km

    const nearby = recentCheckins
      .filter((checkin) => {
        if (!checkin.latitude || !checkin.longitude) return false;

        // Skip self
        if (excludeUserId && checkin.userId?._id?.toString() === excludeUserId)
          return false;

        // 🌍 Haversine distance formula
        const dLat = toRad(checkin.latitude - latitude);
        const dLon = toRad(checkin.longitude - longitude);
        const a =
          Math.sin(dLat / 2) ** 2 +
          Math.cos(toRad(latitude)) *
            Math.cos(toRad(checkin.latitude)) *
            Math.sin(dLon / 2) ** 2;
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        const distance = R * c;

        checkin.distance = distance.toFixed(2);
        return distance <= radius;
      })
      .sort((a, b) => parseFloat(a.distance) - parseFloat(b.distance));

    // 🧾 Format response
    res.json({
      success: true,
      count: nearby.length,
      hikers: nearby.map((c) => ({
        userId: c.userId?._id || c.userId,
        name: c.userId?.name || "Unknown Hiker", // ✅ fixed here
        profileImage: c.userId?.profileImage || "",
        latitude: c.latitude,
        longitude: c.longitude,
        distance: c.distance,
        checkinTime: c.checkinTime,
        note: c.extraData?.note || "",
      })),
    });
  } catch (err) {
    console.error("❌ Error fetching nearby check-ins:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Get specific group details (populated version)
router.get("/group/:groupId", async (req, res) => {
  try {
    const { groupId } = req.params;

    const group = await TrailGroup.findById(groupId)
      .populate("members.userId", "name profileImage email") // 🧠 key part
      .lean();

    if (!group) {
      return res.status(404).json({ error: "Group not found" });
    }

    res.json({ success: true, group });
  } catch (err) {
    console.error("❌ Error fetching group:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Create new trail group with invited members
router.post("/create-group", async (req, res) => {
  try {
    const { groupName, createdBy, creatorName, trailName, invitedMembers } =
      req.body;

    if (!groupName || !createdBy) {
      return res.status(400).json({ error: "Missing groupName or createdBy" });
    }

    // Prepare members array
    const members = [
      {
        userId: createdBy,
        role: "leader",
        name: creatorName || "Leader",
        status: "active",
      },
    ];

    // Add invited members with 'invited' status
    if (invitedMembers && Array.isArray(invitedMembers)) {
      invitedMembers.forEach((member) => {
        members.push({
          userId: member.userId,
          name: member.name || "Invited Member",
          latitude: member.latitude,
          longitude: member.longitude,
          role: "member",
          status: "invited",
        });
      });
    }

    const group = await TrailGroup.create({
      groupName,
      createdBy,
      members,
      activeTrail: {
        trailName: trailName || "Unnamed Trail",
        status: "active",
      },
    });

    console.log(`✅ Group created: ${groupName}`);
    console.log(`   Leader: ${creatorName}`);
    console.log(`   Invited: ${invitedMembers?.length || 0} members`);

    res.json({ success: true, group });
  } catch (err) {
    console.error("❌ Error creating group:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Update member location
router.post("/update-location", async (req, res) => {
  try {
    const { groupId, userId, latitude, longitude, name } = req.body;
    if (!groupId || !userId || !latitude || !longitude) {
      return res.status(400).json({ error: "Missing fields" });
    }

    const group = await TrailGroup.findById(groupId);
    if (!group) return res.status(404).json({ error: "Group not found" });

    const member = group.members.find((m) => m.userId.toString() === userId);
    if (member) {
      member.latitude = latitude;
      member.longitude = longitude;
      member.lastUpdated = new Date(new Date().getTime() + 8 * 60 * 60 * 1000);
      if (name) member.name = name;
    } else {
      // Add new member if not exists
      group.members.push({
        userId,
        name: name || "Hiker",
        latitude,
        longitude,
        role: "member",
        status: "active",
        lastUpdated: new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
      });
    }

    await group.save();
    res.json({ success: true, group });
  } catch (err) {
    console.error("❌ Error updating location:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Add member to group
router.post("/add-member", async (req, res) => {
  try {
    const { groupId, userId, name } = req.body;

    if (!groupId || !userId) {
      return res.status(400).json({ error: "Missing groupId or userId" });
    }

    const group = await TrailGroup.findById(groupId);
    if (!group) return res.status(404).json({ error: "Group not found" });

    const existingMember = group.members.find(
      (m) => m.userId.toString() === userId
    );
    if (existingMember) {
      return res.status(400).json({ error: "Member already in group" });
    }

    group.members.push({
      userId,
      name: name || "New Member",
      role: "member",
      status: "active",
    });

    await group.save();
    res.json({ success: true, group });
  } catch (err) {
    console.error("❌ Error adding member:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Leave group
router.post("/leave-group", async (req, res) => {
  try {
    const { groupId, userId } = req.body;

    if (!groupId || !userId) {
      return res.status(400).json({ error: "Missing groupId or userId" });
    }

    const group = await TrailGroup.findById(groupId);
    if (!group) return res.status(404).json({ error: "Group not found" });

    const initialCount = group.members.length;
    group.members = group.members.filter((m) => m.userId.toString() !== userId);

    if (group.members.length === initialCount) {
      return res.status(400).json({ error: "User not in group" });
    }

    await group.save();
    console.log(`👋 User left group: ${group.groupName}`);
    res.json({ success: true, message: "Left group successfully" });
  } catch (err) {
    console.error("❌ Error leaving group:", err);
    res.status(500).json({ error: "Server error" });
  }
});
//--------------------------------------------------------------------------------- Using API -----------------------------------------------------------------------------

// ✅ Accept group invitation
router.post("/accept-invitation", async (req, res) => {
  try {
    const { groupId, userId } = req.body;

    if (!groupId || !userId) {
      return res.status(400).json({ error: "Missing groupId or userId" });
    }

    const group = await TrailGroup.findById(groupId);
    if (!group) return res.status(404).json({ error: "Group not found" });

    const member = group.members.find((m) => m.userId.toString() === userId);
    if (!member) {
      return res.status(404).json({ error: "Invitation not found" });
    }

    if (member.status !== "invited") {
      return res.status(400).json({ error: "No pending invitation" });
    }

    // Update member status to active
    member.status = "active";
    await group.save();

    console.log(`✅ ${member.name} accepted invitation to ${group.groupName}`);
    res.json({ success: true, group });
  } catch (err) {
    console.error("❌ Error accepting invitation:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Decline group invitation
router.post("/decline-invitation", async (req, res) => {
  try {
    const { groupId, userId } = req.body;

    if (!groupId || !userId) {
      return res.status(400).json({ error: "Missing groupId or userId" });
    }

    const group = await TrailGroup.findById(groupId);
    if (!group) return res.status(404).json({ error: "Group not found" });

    const member = group.members.find((m) => m.userId.toString() === userId);
    if (!member) {
      return res.status(404).json({ error: "Invitation not found" });
    }

    if (member.status !== "invited") {
      return res.status(400).json({ error: "No pending invitation" });
    }

    // Update member status to declined
    member.status = "declined";
    await group.save();

    console.log(`❌ ${member.name} declined invitation to ${group.groupName}`);
    res.json({ success: true, message: "Invitation declined" });
  } catch (err) {
    console.error("❌ Error declining invitation:", err);
    res.status(500).json({ error: "Server error" });
  }
});

// ✅ Get pending invitations for a user
router.get("/pending-invitations/:userId", async (req, res) => {
  try {
    const { userId } = req.params;

    const groups = await TrailGroup.find({
      "members.userId": userId,
      "members.status": "invited",
    });

    const invitations = groups
      .map((group) => {
        const member = group.members.find(
          (m) => m.userId.toString() === userId && m.status === "invited"
        );
        if (!member) return null;

        return {
          groupId: group._id,
          groupName: group.groupName,
          trailName: group.activeTrail?.trailName || "No Trail",
          createdAt: group.createdAt,
          memberCount: group.members.filter((m) => m.status === "active")
            .length,
        };
      })
      .filter((inv) => inv !== null);

    res.json({ success: true, invitations });
  } catch (err) {
    console.error("❌ Error fetching invitations:", err);
    res.status(500).json({ error: "Server error" });
  }
});

export default router;

/* ---------------------------------------------
 🧩 Schemas
----------------------------------------------*/

// ✅ Save trail history
router.post("/save-trail-history", async (req, res) => {
  try {
    const {
      groupId,
      trailName,
      groupName,
      userId,
      userName,
      startTime,
      endTime,
      duration,
      totalDistance,
      averageSpeed,
      path,
      participants,
      status = "completed"
    } = req.body;

    // Validate required fields
    if (!groupId || !trailName || !userId || !userName || !startTime || !endTime || !duration || totalDistance === undefined || !averageSpeed) {
      return res.status(400).json({ 
        error: "Missing required fields",
        required: ["groupId", "trailName", "userId", "userName", "startTime", "endTime", "duration", "totalDistance", "averageSpeed"]
      });
    }

    // Create new trail history record
    const trailHistory = new TrailHistory({
      groupId,
      trailName,
      groupName,
      userId,
      userName,
      startTime: new Date(startTime),
      endTime: new Date(endTime),
      duration,
      totalDistance,
      averageSpeed,
      path: path || [],
      participants: participants || [],
      status
    });

    const savedHistory = await trailHistory.save();
    
    console.log("✅ Trail history saved:", savedHistory._id);
    res.status(201).json({
      success: true,
      message: "Trail history saved successfully",
      trailHistory: savedHistory
    });

  } catch (error) {
    console.error("❌ Error saving trail history:", error);
    res.status(500).json({ 
      error: "Failed to save trail history",
      details: error.message 
    });
  }
});

// ✅ Get user's trail history
router.get("/trail-history/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const { page = 1, limit = 10 } = req.query;

    if (!userId) {
      return res.status(400).json({ error: "User ID is required" });
    }

    const skip = (page - 1) * limit;
    
    const trailHistory = await TrailHistory.find({ userId })
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit))
      .populate("participants.userId", "name")
      .exec();

    const totalCount = await TrailHistory.countDocuments({ userId });

    res.status(200).json({
      success: true,
      trailHistory,
      pagination: {
        currentPage: parseInt(page),
        totalPages: Math.ceil(totalCount / limit),
        totalCount,
        hasMore: skip + trailHistory.length < totalCount
      }
    });

  } catch (error) {
    console.error("❌ Error fetching trail history:", error);
    res.status(500).json({ 
      error: "Failed to fetch trail history",
      details: error.message 
    });
  }
});

// ✅ Get specific trail history by ID
router.get("/trail-history-detail/:historyId", async (req, res) => {
  try {
    const { historyId } = req.params;

    if (!historyId) {
      return res.status(400).json({ error: "History ID is required" });
    }

    const trailHistory = await TrailHistory.findById(historyId)
      .populate("userId", "name profileImage")
      .populate("participants.userId", "name profileImage")
      .populate("groupId", "groupName")
      .exec();

    if (!trailHistory) {
      return res.status(404).json({ error: "Trail history not found" });
    }

    res.status(200).json({
      success: true,
      trailHistory
    });

  } catch (error) {
    console.error("❌ Error fetching trail history detail:", error);
    res.status(500).json({ 
      error: "Failed to fetch trail history detail",
      details: error.message 
    });
  }
});

//--------------------------------------------------------------------------------- Schema Definitions (Commented) -----------------------------------------------------------------------------
// const pathSchema = new mongoose.Schema({
//   lat: Number,
//   lng: Number,
//   timestamp: { type: Date, default: Date.now },
// });

// const memberSchema = new mongoose.Schema({
//   userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
//   name: String,
//   latitude: Number,
//   longitude: Number,
//   lastUpdated: {
//     type: Date,
//     default: () => new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
//   },
//   role: { type: String, enum: ["leader", "member"], default: "member" },
//   status: {
//     type: String,
//     enum: ["active", "invited", "declined"],
//     default: "active",
//   },
// });

// const trailSchema = new mongoose.Schema({
//   trailName: String,
//   startTime: {
//     type: Date,
//     default: () => new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
//   },
//   endTime: Date,
//   path: [pathSchema],
//   status: { type: String, enum: ["active", "completed"], default: "active" },
// });

// const trailGroupSchema = new mongoose.Schema(
//   {
//     groupName: { type: String, required: true },
//     createdBy: {
//       type: mongoose.Schema.Types.ObjectId,
//       ref: "User",
//       required: true,
//     },
//     members: [memberSchema],
//     activeTrail: trailSchema,
//   },
//   { timestamps: true }
// );

// const TrailGroup = mongoose.model("TrailGroup", trailGroupSchema);

// const checkinSchema = new mongoose.Schema({
//   userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
//   latitude: Number,
//   longitude: Number,
//   checkinTime: { type: Date, default: Date.now },
//   lastCheckinTime: Date,
//   extraData: mongoose.Schema.Types.Mixed,
// });

// const Checkin = mongoose.model("Checkin", checkinSchema, "checkins");
