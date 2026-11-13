import { execSync } from "node:child_process";
import fs from "node:fs";

const ffmpeg = "C:/Users/Icaro/AppData/Local/Programs/Stremio/ffmpeg.exe";
const src = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/tongobriga_omni_raw.mp4";
const outDir = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/test_encodes";

if (!fs.existsSync(outDir)) fs.mkdirSync(outDir, { recursive: true });

const tests = [
  { name: "test_q7_nog", args: "-c:v libtheora -q:v 7 -c:a libvorbis -q:a 3" },
  { name: "test_q5", args: "-c:v libtheora -q:v 5 -c:a libvorbis -q:a 3" },
  { name: "test_b2000", args: "-c:v libtheora -b:v 2000k -c:a libvorbis -b:a 128k" },
  { name: "test_g12", args: "-c:v libtheora -q:v 6 -g 12 -keyint_min 12 -c:a libvorbis -q:a 3" },
  { name: "test_yuv420p_explicit", args: "-pix_fmt yuv420p -c:v libtheora -q:v 6 -c:a libvorbis -q:a 3" },
  { name: "test_crop720", args: "-vf crop=1280:720:0:0 -pix_fmt yuv420p -c:v libtheora -q:v 7 -c:a libvorbis -q:a 3" }
];

for (const t of tests) {
  const outFile = `${outDir}/${t.name}.ogv`;
  try {
    execSync(`"${ffmpeg}" -y -ss 0 -t 2 -i "${src}" ${t.args} "${outFile}"`, { stdio: "ignore" });
    const check = execSync(`"${ffmpeg}" -v error -i "${outFile}" -f null - 2>&1`).toString();
    console.log(`[${t.name}] errors: ${check.trim() ? check.trim().split("\n").length : 0} lines`);
    if (!check.trim()) console.log(`SUCCESS on ${t.name}!`);
  } catch (err) {
    console.log(`[${t.name}] failed: ${err.message.slice(0, 100)}`);
  }
}

