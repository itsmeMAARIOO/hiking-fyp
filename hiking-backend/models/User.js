// 📄 hiking-backend/models/User.js
import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String, default: "" },
  profileImage: { type: String, default: "" },
  emergencyContact: {
    name: { type: String, default: "" },
    phone: { type: String, default: "" },
  },
  settings: {
    pushNotifications: { type: Boolean, default: false },
    locationSharing: { type: Boolean, default: false },
    fallDetection: { type: Boolean, default: false },
    autoCheckIn: { type: Boolean, default: false },
    weatherAlerts: { type: Boolean, default: false },
  },
});

export default mongoose.model("User", userSchema);
