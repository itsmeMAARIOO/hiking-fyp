import express from "express";
import SavedTrail from "../models/SavedTrail.js";
import cloudinary from "./cloudinary.js";

const router = express.Router();

// Create or update a saved trail for a user
router.post("/", async (req, res) => {
  try {
    const { userId, trail } = req.body || {};
    if (!userId || !trail || !trail.placeId) {
      return res.status(400).json({ message: "invalid payload" });
    }
    const maybeUpload = async () => {
      const src = trail.photoUrl;
      if (!src) return null;
      const upload = await cloudinary.uploader.upload(src, {
        folder: `hikingapp/saved_trails/${userId}`,
        resource_type: "image",
      });
      return upload.secure_url;
    };
    const existing = await SavedTrail.findOne({
      userId,
      placeId: trail.placeId,
    });
    if (existing) {
      // update fields
      let newImageUrl = existing.imageUrl;
      if (!newImageUrl && trail.photoUrl) {
        try {
          newImageUrl = await maybeUpload();
        } catch (_) {}
      }
      Object.assign(existing, {
        name: trail.name ?? existing.name,
        lat: trail.lat ?? existing.lat,
        lon: trail.lon ?? existing.lon,
        rating: trail.rating ?? existing.rating,
        photoReference: trail.photoReference ?? existing.photoReference,
        imageUrl: newImageUrl ?? existing.imageUrl,
        types: Array.isArray(trail.types) ? trail.types : existing.types,
      });
      await existing.save();
      return res.status(200).json({ ok: true, trail: existing });
    }
    let createdImageUrl = null;
    if (trail.photoUrl) {
      try {
        createdImageUrl = await maybeUpload();
      } catch (_) {}
    }
    const created = await SavedTrail.create({
      userId,
      placeId: trail.placeId,
      name: trail.name ?? "",
      lat: trail.lat,
      lon: trail.lon,
      rating: trail.rating,
      photoReference: trail.photoReference,
      imageUrl: createdImageUrl ?? undefined,
      types: Array.isArray(trail.types) ? trail.types : [],
    });
    return res.status(201).json({ ok: true, trail: created });
  } catch (err) {
    console.error("saved-trails create error:", err);
    return res.status(500).json({ message: "server error" });
  }
});

// Get all saved trails for a user
router.get("/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    if (!userId) return res.status(400).json({ message: "userId required" });
    const items = await SavedTrail.find({ userId }).sort({ createdAt: -1 });
    return res.json({ trails: items });
  } catch (err) {
    console.error("saved-trails list error:", err);
    return res.status(500).json({ message: "server error" });
  }
});

// Delete a saved trail by placeId for a user
router.delete("/:userId/:placeId", async (req, res) => {
  try {
    const { userId, placeId } = req.params;
    if (!userId || !placeId) {
      return res.status(400).json({ message: "missing params" });
    }
    await SavedTrail.deleteOne({ userId, placeId });
    return res.json({ ok: true });
  } catch (err) {
    console.error("saved-trails delete error:", err);
    return res.status(500).json({ message: "server error" });
  }
});

export default router;