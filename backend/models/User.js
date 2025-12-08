// 📄 hiking-backend/models/User.js
import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  name: { type: String, required: true },
  email: { type: String, required: true, unique: true },
  password: { type: String, required: true },
  phone: { type: String, default: "" },
  profileImage: { type: String, default: "" },
  emergencyContacts: [
    {
      name: { type: String, default: "" },
      email: { type: String, default: "" },
      phone: { type: String, default: "" },
      share: { type: Boolean, default: false },
    },
  ],
  settings: {
    pushNotifications: { type: Boolean, default: false },
    locationSharing: { type: Boolean, default: false },
    fallDetection: { type: Boolean, default: false },
    autoCheckIn: { type: Boolean, default: false },
    weatherAlerts: { type: Boolean, default: false },
  },
  dateOfBirth: { type: Date },
  gender: { type: String, enum: ["Male", "Female", "Other"] },
  weightKg: { type: Number },
  heightCm: { type: Number },
  bloodType: {
    type: String,
    enum: ["A+", "A-", "B+", "B-", "O+", "O-", "AB+", "AB-"]
  },
  allergies: { type: [String], default: [] },
  resetPasswordToken: { type: String },
  resetPasswordExpires: { type: Date },
});

export default mongoose.model("User", userSchema);
