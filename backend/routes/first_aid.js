import express from "express";
import FirstAidNote from "../models/FirstAidNote.js";
import Guide from "../models/Guide.js";

const router = express.Router();

// Standard Guides
router.get("/guides", async (req, res) => {
  try {
    const guides = await Guide.find({}).sort({ title: 1 }).lean();
    return res.json({ guides });
  } catch (err) {
    return res.status(500).json({ message: "server error" });
  }
});

router.post("/", async (req, res) => {
  try {
    const { userId, title, content } = req.body || {};
    if (!userId || !title) {
      return res.status(400).json({ message: "userId and title required" });
    }
    const note = await FirstAidNote.create({
      userId,
      title: title.trim(),
      content: (content || "").toString(),
    });
    return res.status(201).json({ note });
  } catch (err) {
    return res.status(500).json({ message: "server error" });
  }
});

router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: "userId required" });
    const notes = await FirstAidNote.find({ userId }).sort({ createdAt: -1 });
    return res.json({ notes });
  } catch (err) {
    return res.status(500).json({ message: "server error" });
  }
});

router.put("/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { title, content } = req.body || {};
    if (!id) return res.status(400).json({ message: "id required" });
    const updated = await FirstAidNote.findByIdAndUpdate(
      id,
      { $set: { title, content } },
      { new: true }
    );
    if (!updated) return res.status(404).json({ message: "not found" });
    return res.json({ note: updated });
  } catch (err) {
    return res.status(500).json({ message: "server error" });
  }
});

router.delete("/:userId/:id", async (req, res) => {
  try {
    const { userId, id } = req.params;
    if (!userId || !id) {
      return res.status(400).json({ message: "missing params" });
    }
    const result = await FirstAidNote.deleteOne({ _id: id, userId });
    if (result.deletedCount === 0) {
      return res.status(404).json({ message: "not found" });
    }
    return res.json({ ok: true });
  } catch (err) {
    return res.status(500).json({ message: "server error" });
  }
});

export default router;
