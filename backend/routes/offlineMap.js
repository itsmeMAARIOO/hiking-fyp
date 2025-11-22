// // import express from "express";
// // import fs from "fs";
// // import path from "path";
// // import https from "https";
// // import OfflineMap from "../models/OfflineMap.js";

// // const router = express.Router();

// // Helpers: conversions between lat/lng and tile x/y
// // function long2tile(lon, zoom) {
// //   return Math.floor(((lon + 180) / 360) * Math.pow(2, zoom));
// // }
// // function lat2tile(lat, zoom) {
// //   const latRad = (lat * Math.PI) / 180;
// //   const n = Math.pow(2, zoom);
// //   const y =
// //     (n * (1 - Math.log(Math.tan(latRad) + 1 / Math.cos(latRad)) / Math.PI)) / 2;
// //   return Math.floor(y);
// // }

// // function clamp(val, min, max) {
// //   return Math.max(min, Math.min(max, val));
// // }

// // function tileRangeFromBounds({ neLat, neLng, swLat, swLng }, z) {
// //   const maxIndex = Math.pow(2, z) - 1;
// //   let xMin = long2tile(swLng, z);
// //   let xMax = long2tile(neLng, z);
// //   let yMin = lat2tile(neLat, z); // northern lat maps to smaller y
// //   let yMax = lat2tile(swLat, z); // southern lat maps to larger y

// //   xMin = clamp(xMin, 0, maxIndex);
// //   xMax = clamp(xMax, 0, maxIndex);
// //   yMin = clamp(yMin, 0, maxIndex);
// //   yMax = clamp(yMax, 0, maxIndex);

// //   if (xMax < xMin) [xMin, xMax] = [xMax, xMin];
// //   if (yMax < yMin) [yMin, yMax] = [yMax, yMin];

// //   return { xMin, xMax, yMin, yMax };
// // }

// // function ensureDir(dirPath) {
// //   if (!fs.existsSync(dirPath)) {
// //     fs.mkdirSync(dirPath, { recursive: true });
// //   }
// // }

// // function downloadTile({ z, x, y, destPath, token }) {
// //   return new Promise((resolve, reject) => {
// //     const url = `https://api.mapbox.com/styles/v1/mapbox/streets-v11/tiles/256/${z}/${x}/${y}?access_token=${token}`;

// //     const fileDir = path.dirname(destPath);
// //     ensureDir(fileDir);

// //     const file = fs.createWriteStream(destPath);
// //     https
// //       .get(url, (res) => {
// //         if (res.statusCode !== 200) {
// //           file.close();
// //           fs.unlink(destPath, () => {});
// //           return reject(
// //             new Error(`HTTP ${res.statusCode} for ${z}/${x}/${y}: ${url}`)
// //           );
// //         }
// //         res.pipe(file);
// //         file.on("finish", () => file.close(() => resolve(true)));
// //       })
// //       .on("error", (err) => {
// //         file.close();
// //         fs.unlink(destPath, () => {});
// //         reject(err);
// //       });
// //   });
// // }

// // async function downloadTilesForBounds(mapDoc, token) {
// //   const baseFolder = path.join(
// //     process.cwd(),
// //     "offline-maps",
// //     mapDoc._id.toString()
// //   );
// //   ensureDir(baseFolder);

// //   let total = 0;
// //   let downloaded = 0;

// //   // Compute total tile count first
// //   for (let z = mapDoc.minZoom; z <= mapDoc.maxZoom; z++) {
// //     const { xMin, xMax, yMin, yMax } = tileRangeFromBounds(mapDoc, z);
// //     total += (xMax - xMin + 1) * (yMax - yMin + 1);
// //   }

// //   // Optional safeguard to avoid huge downloads
// //   const MAX_TILES = 5000;
// //   if (total > MAX_TILES) {
// //     throw new Error(
// //       `Selected area too large: ${total} tiles (limit ${MAX_TILES})`
// //     );
// //   }

// //   // Persist initial counters
// //   mapDoc.tileCount = total;
// //   mapDoc.downloaded = 0;
// //   mapDoc.status = "downloading";
// //   mapDoc.baseUrl = `/offline-maps/${mapDoc._id.toString()}`;
// //   await mapDoc.save();

// //   // Download sequentially with small concurrency to avoid throttling
// //   const concurrency = 8;
// //   const queue = [];

// //   for (let z = mapDoc.minZoom; z <= mapDoc.maxZoom; z++) {
// //     const { xMin, xMax, yMin, yMax } = tileRangeFromBounds(mapDoc, z);

// //     for (let x = xMin; x <= xMax; x++) {
// //       for (let y = yMin; y <= yMax; y++) {
// //         const destPath = path.join(baseFolder, `${z}`, `${x}`, `${y}.png`);
// //         const task = async () => {
// //           await downloadTile({ z, x, y, destPath, token });
// //           downloaded++;
// //           if (downloaded % 50 === 0) {
// //             mapDoc.downloaded = downloaded;
// //             await mapDoc.save();
// //           }
// //         };
// //         queue.push(task);

// //         // Run in batches
// //         if (queue.length >= concurrency) {
// //           await Promise.all(queue.splice(0, concurrency).map((fn) => fn()));
// //         }
// //       }
// //     }
// //   }

// //   // Drain remaining
// //   if (queue.length) {
// //     await Promise.all(queue.map((fn) => fn()));
// //   }

// //   mapDoc.downloaded = downloaded;
// //   mapDoc.status = "completed";
// //   await mapDoc.save();
// // }

// // // GET /offline-map/list?userId=...
// // router.get("/offline-map/list", async (req, res) => {
// //   try {
// //     const { userId } = req.query;
// //     if (!userId) return res.status(400).json({ error: "Missing userId" });

// //     const maps = await OfflineMap.find({ userId }).sort({ createdAt: -1 });
// //     res.json({ success: true, maps });
// //   } catch (err) {
// //     console.error("❌ Error listing offline maps:", err);
// //     res.status(500).json({ error: "Server error", details: err.message });
// //   }
// // });

// // // DELETE /offline-map/delete/:id
// // router.delete("/offline-map/delete/:id", async (req, res) => {
// //   try {
// //     const { id } = req.params;
// //     const doc = await OfflineMap.findById(id);
// //     if (!doc) return res.status(404).json({ error: "Map not found" });

// //     await OfflineMap.deleteOne({ _id: id });

// //     // Remove tiles folder
// //     const folder = path.join(process.cwd(), "offline-maps", id);
// //     if (fs.existsSync(folder)) {
// //       fs.rmSync(folder, { recursive: true, force: true });
// //     }

// //     res.json({ success: true });
// //   } catch (err) {
// //     console.error("❌ Error deleting offline map:", err);
// //     res.status(500).json({ error: "Server error", details: err.message });
// //   }
// // });

// export default router;
