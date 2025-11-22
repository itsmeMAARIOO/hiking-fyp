import express from "express";
import multer from "multer";
import path from "path";
import fs from "fs";
import cloudinary from "./cloudinary.js";
import ChatMessage from "../models/ChatMessage.js";

const router = express.Router();

// Ensure tmp upload dir exists
const uploadDir = path.join(process.cwd(), "backend", "uploads", "tmp");
fs.mkdirSync(uploadDir, { recursive: true });

const storage = multer.diskStorage({
  destination: function (req, file, cb) {
    cb(null, uploadDir);
  },
  filename: function (req, file, cb) {
    const uniqueName = `${Date.now()}-${Math.random().toString(36).slice(2)}-${
      file.originalname
    }`;
    cb(null, uniqueName);
  },
});

const upload = multer({ storage });

// GET messages for a group
router.get("/:groupId/messages", async (req, res) => {
  try {
    const { groupId } = req.params;
    const messages = await ChatMessage.find({ groupId }).sort({ createdAt: 1 });
    res.json(messages);
  } catch (err) {
    console.error("Error fetching messages:", err);
    res.status(500).json({ message: "Failed to fetch messages" });
  }
});

// POST text message
router.post("/:groupId/text", async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userId, userName, text } = req.body;
    if (!text || !text.trim()) {
      return res.status(400).json({ message: "Text is required" });
    }
    const msg = await ChatMessage.create({
      groupId,
      userId,
      userName,
      text: text.trim(),
    });
    const io = req.app.get("io");
    if (io) io.to(groupId).emit("chat:new", msg);
    res.status(201).json(msg);
  } catch (err) {
    console.error("Error sending text message:", err);
    res.status(500).json({ message: "Failed to send text message" });
  }
});

// POST image message
router.post("/:groupId/images", upload.single("image"), async (req, res) => {
  try {
    const { groupId } = req.params;
    const { userId, userName } = req.body;
    const filePath = req.file?.path;
    if (!filePath)
      return res.status(400).json({ message: "Image file is required" });

    const uploadResult = await cloudinary.uploader.upload(filePath, {
      folder: `hikingapp/groups/${groupId}`,
      resource_type: "image",
    });

    const msg = await ChatMessage.create({
      groupId,
      userId,
      userName,
      imageUrl: uploadResult.secure_url,
      publicId: uploadResult.public_id,
    });

    const io = req.app.get("io");
    if (io) io.to(groupId).emit("chat:new", msg);

    res.status(201).json(msg);
  } catch (err) {
    console.error("Error uploading image:", err);
    res.status(500).json({ message: "Failed to upload image" });
  }
});

export default router;

// DELETE a message (image or text) by id with ownership check
router.delete('/:groupId/messages/:id', async (req, res) => {
  try {
    const { groupId, id } = req.params;
    const { userId } = req.body || {};
    if (!userId) {
      return res.status(400).json({ message: 'userId required' });
    }

    const msg = await ChatMessage.findById(id);
    if (!msg || msg.groupId !== groupId) {
      return res.status(404).json({ message: 'Message not found' });
    }
    if (msg.userId !== userId) {
      return res.status(403).json({ message: 'Not allowed to delete this message' });
    }

    // Attempt to delete Cloudinary asset if present
    if (msg.publicId) {
      try {
        await cloudinary.uploader.destroy(msg.publicId);
      } catch (e) {
        console.warn('Cloudinary destroy failed:', e?.message || e);
      }
    }

    await msg.deleteOne();

    const io = req.app.get('io');
    if (io) io.to(groupId).emit('chat:delete', { _id: id });

    res.json({ success: true, _id: id });
  } catch (err) {
    console.error('Error deleting message:', err);
    res.status(500).json({ message: 'Failed to delete message' });
  }
});
