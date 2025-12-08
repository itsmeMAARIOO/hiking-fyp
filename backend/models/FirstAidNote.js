import mongoose from "mongoose";

const FirstAidNoteSchema = new mongoose.Schema(
  {
    userId: { type: mongoose.Schema.Types.ObjectId, ref: "User", required: true },
    title: { type: String, required: true },
    content: { type: String, default: "" },
  },
  { timestamps: true }
);

export default mongoose.models.FirstAidNote ||
  mongoose.model("FirstAidNote", FirstAidNoteSchema, "first_aid_notes");