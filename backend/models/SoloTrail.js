import mongoose from "mongoose";

const soloTrailSchema = new mongoose.Schema(
  {
    trailName: { type: String, required: true },
    trailDescription: { type: String },
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    startTime: {
      type: Date,
      default: Date.now,
    },
    endTime: Date,
    expectedEndTime: Date,
    overdueNotified: { type: Boolean, default: false },
    notifiedContacts: [
      {
        name: String,
        email: String,
      },
    ],
    // latest live location info for solo tracking
    latestLatitude: Number,
    latestLongitude: Number,
    lastUpdated: {
      type: Date,
      default: Date.now,
    },
    status: { type: String, enum: ["active", "completed"], default: "active" },
  },
  { timestamps: true }
);

export default mongoose.models.SoloTrail ||
  mongoose.model("SoloTrail", soloTrailSchema);
