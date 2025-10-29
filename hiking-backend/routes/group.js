import express from "express";
import mongoose from "mongoose";
import TrailGroup from "../models/TrailGroup.js";
import Checkin from "../models/Checkin.js";
const router = express.Router();

/* ---------------------------------------------
 🚀 API Routes
----------------------------------------------*/

// ✅ Count completed group hikes by user (user is a member and trail completed)
router.get("/count/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) {
      return res.status(400).json({ error: "Missing userId" });
    }

    const count = await TrailGroup.countDocuments({
      "members.userId": userId,
      "activeTrail.status": "completed",
    });

    res.json({ success: true, userId, totalGroupHikes: count });
  } catch (err) {
    console.error("❌ Error counting group hikes:", err);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

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

// routes/trailGroupRoutes.js
router.get("/invitation/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const group = await TrailGroup.findOne({
      "members.userId": userId,
      "members.status": "invited",
    });

    if (!group) {
      return res.status(404).json({ message: "No invitations found" });
    }

    res.json(group);
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

router.put("/invitation/respond", async (req, res) => {
  try {
    const { userId, groupId, status } = req.body; // status = 'accepted' | 'rejected'

    const group = await TrailGroup.findOneAndUpdate(
      { _id: groupId, "members.userId": userId },
      { $set: { "members.$.status": status } },
      { new: true }
    );

    if (!group) {
      return res.status(404).json({ message: "Invitation not found" });
    }

    res.json({ message: `Invitation ${status}`, group });
  } catch (error) {
    console.error(error);
    res.status(500).json({ message: "Server error" });
  }
});

router.get("/groups/:groupId", async (req, res) => {
  try {
    const group = await TrailGroup.findById(req.params.groupId);
    if (!group) {
      return res.status(404).json({ error: "Group not found" });
    }
    res.json({ group });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Add this route to your trailGroupRoutes.js

// ✅ End trail (creator only - ends for everyone)
router.post("/end-trail", async (req, res) => {
  try {
    const { groupId, userId } = req.body;

    console.log("📍 End trail request:", { groupId, userId });

    if (!groupId || !userId) {
      return res.status(400).json({ error: "Missing groupId or userId" });
    }

    const group = await TrailGroup.findById(groupId);
    if (!group) {
      console.log("❌ Group not found:", groupId);
      return res.status(404).json({ error: "Group not found" });
    }

    console.log("✅ Group found:", group.groupName);
    console.log("   Creator:", group.createdBy);
    console.log("   Requesting user:", userId);

    // Verify user is the creator
    if (group.createdBy.toString() !== userId) {
      console.log("❌ Not creator - access denied");
      return res
        .status(403)
        .json({ error: "Only the creator can end the trail" });
    }

    // Mark the active trail as completed per schema
    if (group.activeTrail) {
      group.activeTrail.status = "completed";
      group.activeTrail.endTime = new Date();
    }

    await group.save();

    console.log(`🏁 Trail marked completed by creator: ${group.groupName}`);
    res.json({
      success: true,
      message: "Trail completed for all members",
      group,
    });
  } catch (err) {
    console.error("❌ Error ending trail:", err);
    console.error("   Stack:", err.stack);
    res.status(500).json({ error: "Server error", details: err.message });
  }
});

export default router;
