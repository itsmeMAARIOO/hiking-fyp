import mongoose from "mongoose";

const pathSchema = new mongoose.Schema({
  lat: Number,
  lng: Number,
  timestamp: { type: Date, default: Date.now },
});

const memberSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  name: String,
  latitude: Number,
  longitude: Number,
  lastUpdated: {
    type: Date,
    default: () => new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
  },
  role: { type: String, enum: ["leader", "member"], default: "member" },
  status: {
    type: String,
    enum: ["active", "invited", "declined"],
    default: "active",
  },
});

const trailSchema = new mongoose.Schema({
  trailName: String,
  trailDescription: String,
  startTime: {
    type: Date,
    default: () => new Date(new Date().getTime() + 8 * 60 * 60 * 1000),
  },
  endTime: Date,
  path: [pathSchema],
  status: { type: String, enum: ["active", "completed"], default: "active" },
});

const trailGroupSchema = new mongoose.Schema(
  {
    groupName: { type: String, required: true },
    createdBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    members: [memberSchema],
    activeTrail: trailSchema,
  },
  { timestamps: true }
);

export default mongoose.models.TrailGroup ||
  mongoose.model("TrailGroup", trailGroupSchema);
