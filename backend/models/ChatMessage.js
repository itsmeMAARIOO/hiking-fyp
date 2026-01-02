import mongoose from "mongoose";

const ChatMessageSchema = new mongoose.Schema(
  {
    groupId: { type: String, required: true, index: true },
    userId: { type: String, required: true },
    userName: { type: String, required: true },
    text: { type: String },
    imageUrl: { type: String },
    // Store Cloudinary public_id to allow deletion of the asset later
    publicId: { type: String },
    seenBy: [
      {
        userId: { type: String },
        seenAt: { type: Date, default: Date.now },
      },
    ],
  },
  { timestamps: true }
);

export default mongoose.models.ChatMessage ||
  mongoose.model("ChatMessage", ChatMessageSchema);