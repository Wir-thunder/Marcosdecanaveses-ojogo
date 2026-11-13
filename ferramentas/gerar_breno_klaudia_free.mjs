import fs from "node:fs";
import path from "node:path";

const RAW_DIR = path.resolve("Assets/Source/raw/tongobriga_roster_v2");
const ARTIFACT_DIR = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89";
const BRENO_CLEAN_REF = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/breno_center_only_ref.jpg";
const KLAUDIA_CLEAN_REF = "C:/Users/Icaro/.gemini/antigravity/brain/d230022c-e2cb-4685-b15f-9b28e390df89/scratch/klaudia_clean_16x9_ref.jpg";

fs.mkdirSync(RAW_DIR, { recursive: true });
const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function fetchJson(url, options = {}, timeoutMs = 25000) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const res = await fetch(url, { ...options, signal: ctrl.signal });
    const text = await res.text();
    if (!res.ok) throw new Error(`HTTP ${res.status}: ${text.slice(0, 220)}`);
    return JSON.parse(text);
  } finally {
    clearTimeout(t);
  }
}

async function detectApiPrefix(spaceUrl) {
  for (const prefix of ["/gradio_api", ""]) {
    try {
      const info = await fetchJson(`${spaceUrl}${prefix}/info`, {}, 15000);
      return { prefix, info };
    } catch (_) {}
  }
  throw new Error(`Could not reach Gradio /info on ${spaceUrl}`);
}

async function uploadFileToGradio(spaceUrl, prefix, filePath) {
  const bytes = fs.readFileSync(filePath);
  const blob = new Blob([bytes], { type: "image/jpeg" });
  const form = new FormData();
  form.append("files", blob, path.basename(filePath));

  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), 30000);
  try {
    const res = await fetch(`${spaceUrl}${prefix}/upload`, {
      method: "POST",
      body: form,
      signal: ctrl.signal
    });
    const text = await res.text();
    if (!res.ok) throw new Error(`Upload HTTP ${res.status}: ${text.slice(0, 200)}`);
    const paths = JSON.parse(text);
    if (!Array.isArray(paths) || !paths[0]) throw new Error(`Unexpected upload response: ${text}`);
    return paths[0];
  } finally {
    clearTimeout(t);
  }
}

async function callGradioSse(spaceUrl, prefix, endpointName, dataArray, timeoutMs = 150000) {
  const cleanEp = endpointName.replace(/^\//, "");
  const postRes = await fetchJson(
    `${spaceUrl}${prefix}/call/${cleanEp}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ data: dataArray })
    },
    30000
  );

  const eventId = postRes.event_id;
  if (!eventId) throw new Error(`Missing event_id: ${JSON.stringify(postRes)}`);

  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), timeoutMs);
  try {
    const sseRes = await fetch(`${spaceUrl}${prefix}/call/${cleanEp}/${eventId}`, {
      signal: ctrl.signal
    });
    const sseText = await sseRes.text();
    if (!sseRes.ok) throw new Error(`SSE HTTP ${sseRes.status}: ${sseText.slice(0, 250)}`);

    const lines = sseText.split(/\r?\n/);
    let lastEvent = "";
    for (const line of lines) {
      if (line.startsWith("event:")) {
        lastEvent = line.slice(6).trim();
      } else if (line.startsWith("data:")) {
        const raw = line.slice(5).trim();
        if (lastEvent === "error") throw new Error(`Gradio SSE error: ${raw}`);
        if (lastEvent === "complete") return JSON.parse(raw);
      }
    }
    throw new Error(`SSE finished without complete event: ${sseText.slice(0, 300)}`);
  } finally {
    clearTimeout(t);
  }
}

function extractImageUrl(spaceUrl, prefix, resultData) {
  if (!Array.isArray(resultData) || resultData.length === 0) return null;
  const first = resultData[0];
  if (typeof first === "string") return first.startsWith("http") ? first : `${spaceUrl}${prefix}/file=${first}`;
  if (first && typeof first === "object") {
    if (first.url) return first.url;
    if (first.path) return `${spaceUrl}${prefix}/file=${first.path}`;
    if (first.image && first.image.url) return first.image.url;
    if (first.image && first.image.path) return `${spaceUrl}${prefix}/file=${first.image.path}`;
  }
  return null;
}

async function downloadBinary(url) {
  const ctrl = new AbortController();
  const t = setTimeout(() => ctrl.abort(), 45000);
  try {
    const res = await fetch(url, { signal: ctrl.signal });
    if (!res.ok) throw new Error(`Download HTTP ${res.status}`);
    const ab = await res.arrayBuffer();
    const buf = Buffer.from(ab);
    if (buf.length < 10000) throw new Error(`Downloaded buffer too small (${buf.length} bytes)`);
    return buf;
  } finally {
    clearTimeout(t);
  }
}

async function generateWithFluxKontextRetry(label, refPath, prompt, seed = 42, steps = 18) {
  const spaceUrl = "https://black-forest-labs-flux-1-kontext-dev.hf.space";
  for (let attempt = 1; attempt <= 3; attempt++) {
    try {
      console.log(`[${label}] Attempt ${attempt}/3 on FLUX.1-Kontext...`);
      const { prefix, info } = await detectApiPrefix(spaceUrl);
      const endpoints = info.named_endpoints || {};
      const epKey = Object.keys(endpoints).find((k) => k.includes("infer")) || Object.keys(endpoints)[0];
      const params = endpoints[epKey].parameters || [];

      const uploadedPath = await uploadFileToGradio(spaceUrl, prefix, refPath);
      const fileObj = { path: uploadedPath, meta: { _type: "gradio.FileData" } };
      const data = params.map((p) => {
        const name = (p.parameter_name || p.label || "").toLowerCase();
        const comp = (p.component || "").toLowerCase();
        if (comp.includes("image") || name.includes("image")) return fileObj;
        if (name.includes("prompt")) return prompt;
        if (name.includes("seed") && !name.includes("random")) return seed;
        if (name.includes("random")) return false;
        if (name.includes("guidance")) return 3.5;
        if (name.includes("step")) return steps;
        return p.parameter_default !== undefined ? p.parameter_default : null;
      });

      const resData = await callGradioSse(spaceUrl, prefix, epKey, data, 180000);
      const imgUrl = extractImageUrl(spaceUrl, prefix, resData);
      if (!imgUrl) throw new Error(`Could not find image URL`);
      return await downloadBinary(imgUrl);
    } catch (err) {
      console.warn(`[${label}] Attempt ${attempt} error: ${err.message}`);
      if (err.message.includes("Could not reach Gradio /info")) {
        throw err;
      }
      if (attempt < 3) {
        console.log(`[${label}] Waiting 45s for ZeroGPU cooldown before retry...`);
        await sleep(45000);
      } else {
        throw err;
      }
    }
  }
}

const BRENO_COMPLETE_PROMPT =
  "Keep the exact center full-body pixel-art Gaulish warrior, dark charcoal slate background, and thin antique gold Celtic knotwork corner borders, and complete the 3-part 1990s Capcom CPS2 32-bit arcade pixel art character showcase sheet: ON THE LEFT empty area, add a large close-up arcade portrait bust of this exact same golden-blond Gaulish warrior (matching his blond swept-back hair, blue woad face war-paint, braided golden mustache/beard, and fierce grin, adding a twisted gold torque around his neck and a bronze Carnyx boar war-horn tip over his shoulder); ON THE RIGHT empty area, add a full-body dynamic special attack pose of this exact same blond Gaulish warrior swinging a glowing golden-blue broadsword shockwave cleave while blowing a bronze boar-headed Carnyx war-horn. Crisp 32-bit retro arcade pixel art, sharp dark pixel outlines, no text.";

const KLAUDIA_COMPLETE_PROMPT =
  "Keep the exact dark charcoal slate background and thin antique gold knotwork corner borders, remove the white rectangular wall behind the woman on the left, and transform her into a 3-part 1990s Capcom CPS2 SNK NeoGeo 32-bit arcade pixel art fighting game character showcase sheet of Klaudia, The Slav, preserving her exact facial likeness across all three poses: short wavy dark chestnut-brown chin-length bob haircut with side-swept bangs, bright hazel-green eyes with sharp black winged cat-eye eyeliner, silver stud earring, and radiant wide toothy smile with bright crimson-red lipstick. ON THE LEFT, large close-up 32-bit pixel art arcade portrait bust floating cleanly on the dark slate background; IN THE CENTER, full-body 2D fighting game idle combat stance wearing a dark espresso-brown Slavic warrior battle-tunic with black floral embroidery matching her dress, crimson belt sash, leather bracers and high boots, wielding a curved Slavic sabre sword; ON THE RIGHT, full-body dynamic spinning sabre slash special attack unleashing golden-amber Perun lightning bolts and icy frost crystals. Crisp hand-pixeled 32-bit arcade pixel art, sharp dark pixel outlines, no text.";

async function main() {
  const brenoBuf = await generateWithFluxKontextRetry("Breno", BRENO_CLEAN_REF, BRENO_COMPLETE_PROMPT, 31415, 18);
  fs.writeFileSync(path.join(RAW_DIR, "05_breno_gaules_concept.webp"), brenoBuf);
  fs.writeFileSync(path.join(ARTIFACT_DIR, "breno_gaules_showcase_final.webp"), brenoBuf);
  console.log(`[SAVED BRENO FINAL] ${brenoBuf.length} bytes`);

  console.log("Waiting 40s for ZeroGPU window reset before generating Klaudia...");
  await sleep(40000);

  const klaudiaBuf = await generateWithFluxKontextRetry("Klaudia", KLAUDIA_CLEAN_REF, KLAUDIA_COMPLETE_PROMPT, 88314, 18);
  fs.writeFileSync(path.join(RAW_DIR, "09_klaudia_the_slav_concept.webp"), klaudiaBuf);
  fs.writeFileSync(path.join(ARTIFACT_DIR, "klaudia_the_slav_showcase_final.webp"), klaudiaBuf);
  console.log(`[SAVED KLAUDIA FINAL] ${klaudiaBuf.length} bytes`);
}

await main();
