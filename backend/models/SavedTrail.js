import mongoose from "mongoose";

const SavedTrailSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    placeId: { type: String, required: true },
    name: { type: String, default: "" },
    lat: { type: Number },
    lon: { type: Number },
    rating: { type: Number },
    photoReference: { type: String },
    imageUrl: { type: String },
    types: { type: [String], default: [] },
  },
  { timestamps: true }
);

// Prevent model overwrite error in dev/hot-reload
export default mongoose.models.SavedTrail ||
  mongoose.model("SavedTrail", SavedTrailSchema, "saved_trails");