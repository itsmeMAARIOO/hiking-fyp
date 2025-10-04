import mongoose from "mongoose";

const checkInSchema = new mongoose.Schema({
  userId: { type: String, required: true },
  checkinTime: { type: Date, required: true },
  lastCheckinTime: { type: Date, required: true },
  latitude: Number,
  longitude: Number,
  extraData: Object,
});

export default mongoose.model("CheckIn", checkInSchema);
