// import mongoose from "mongoose";

// const checkInSchema = new mongoose.Schema({
//   userId: { type: String, required: true },
//   checkinTime: { type: Date, required: true },
//   lastCheckinTime: { type: Date, required: true },
//   latitude: Number,
//   longitude: Number,
//   extraData: Object,
// });

// export default mongoose.model("CheckIn", checkInSchema);

import mongoose from "mongoose";

const checkinSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
  latitude: { type: Number, required: false },
  longitude: { type: Number, required: false },
  checkinTime: { type: Date, default: Date.now },
  lastCheckinTime: { type: Date, default: Date.now },
  extraData: mongoose.Schema.Types.Mixed,
});

// Prevent model overwrite error on hot reload
export default mongoose.models.Checkin ||
  mongoose.model("Checkin", checkinSchema, "checkins");
