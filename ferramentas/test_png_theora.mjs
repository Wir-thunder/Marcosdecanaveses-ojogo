import { execSync } from "node:child_process";
import fs from "node:fs";

const ffmpeg = "C:/Users/Icaro/AppData/Local/Programs/Stremio/ffmpeg.exe";
const framesDir = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/test_frames";
const outFile = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/test_from_png.ogv";

if (!fs.existsSync(framesDir)) fs.mkdirSync(framesDir, { recursive: true });

// Extract 24 frames (1 second) as PNG
execSync(`"${ffmpeg}" -y -ss 0 -t 1 -i "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/tongobriga_omni_raw.mp4" "${framesDir}/frame_%03d.png"`, { stdio: "ignore" });

// Encode to OGV with standard settings
execSync(`"${ffmpeg}" -y -framerate 24 -i "${framesDir}/frame_%03d.png" -c:v libtheora -q:v 7 -pix_fmt yuv420p "${outFile}"`, { stdio: "ignore" });

// Check decode errors
try {
  const check = execSync(`"${ffmpeg}" -v error -i "${outFile}" -f null - 2>&1`).toString();
  console.log("Decode errors from PNG encode:", check.trim() ? check.trim().split("\n").length : 0);
} catch (e) {
  console.log("Error:", e.message);
}

