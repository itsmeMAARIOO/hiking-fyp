// import mongoose from "mongoose";

// const offlineMapSchema = new mongoose.Schema(
//   {
//     userId: {
//       type: mongoose.Schema.Types.ObjectId,
//       ref: "User",
//       required: true,
//     },
//     regionName: { type: String, required: true },
//     neLat: { type: Number, required: true },
//     neLng: { type: Number, required: true },
//     swLat: { type: Number, required: true },
//     swLng: { type: Number, required: true },
//     minZoom: { type: Number, required: true },
//     maxZoom: { type: Number, required: true },

//     tileCount: { type: Number, default: 0 },
//     downloaded: { type: Number, default: 0 },

//     status: {
//       type: String,
//       enum: ["pending", "downloading", "completed", "failed"],
//       default: "pending",
//     },
//     error: { type: String, default: "" },

//     // Base URL for serving tiles statically: `/offline-maps/<_id>`
//     baseUrl: { type: String, default: "" },
//   },
//   { timestamps: true }
// );

// export default mongoose.model("OfflineMap", offlineMapSchema);
