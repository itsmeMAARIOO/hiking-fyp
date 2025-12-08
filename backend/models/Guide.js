import mongoose from "mongoose";

const GuideSchema = new mongoose.Schema(
  {
    title: { type: String, required: true, index: true, unique: true },
    content: { type: [String], default: [] },
  },
  { timestamps: true }
);

export default mongoose.models.Guide || mongoose.model("Guide", GuideSchema);
