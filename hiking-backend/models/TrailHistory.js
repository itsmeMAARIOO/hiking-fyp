import mongoose from "mongoose";

const trailHistorySchema = new mongoose.Schema(
  {
    // Reference to the original trail group
    groupId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "TrailGroup",
      required: true,
    },
    
    // Basic trail information
    trailName: { type: String, required: true },
    groupName: { type: String, required: true },
    
    // User who completed the trail
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    userName: { type: String, required: true },
    
    // Trail timing data
    startTime: { type: Date, required: true },
    endTime: { type: Date, required: true },
    duration: { type: Number, required: true }, // Duration in seconds
    
    // Trail distance and speed data
    totalDistance: { type: Number, required: true }, // Distance in meters
    averageSpeed: { type: Number, required: true }, // Speed in km/h
    
    // Trail path data
    path: [
      {
        latitude: { type: Number, required: true },
        longitude: { type: Number, required: true },
        timestamp: { type: Date, default: Date.now },
      },
    ],
    
    // Additional metadata
    status: {
      type: String,
      enum: ["completed", "abandoned"],
      default: "completed",
    },
    
    // Group members who participated
    participants: [
      {
        userId: { type: mongoose.Schema.Types.ObjectId, ref: "User" },
        name: String,
        role: { type: String, enum: ["leader", "member"] },
      },
    ],
  },
  { timestamps: true }
);

// Index for efficient queries
trailHistorySchema.index({ userId: 1, createdAt: -1 });
trailHistorySchema.index({ groupId: 1 });

export default mongoose.models.TrailHistory ||
  mongoose.model("TrailHistory", trailHistorySchema);