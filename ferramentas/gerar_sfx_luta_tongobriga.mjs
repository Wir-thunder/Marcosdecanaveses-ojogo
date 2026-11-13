import fs from "node:fs";
import path from "node:path";

const SFX_DIR = path.resolve("Assets/Audio/SFX");
fs.mkdirSync(SFX_DIR, { recursive: true });

// 1. Copy/normalize existing raw MP3s into semantic combat filenames
const copies = [
  ["Fighting_game_super__#4-1793632253693.mp3", "super_flash_freeze.mp3"],
  ["Dramatic_heavy_cinem_#4-1793632360787.mp3", "ko_impact_boom.mp3"],
  ["Quick_cloth_swoosh_a_#4-1793632283424.mp3", "dash_esquiva.mp3"]
];

for (const [srcName, dstName] of copies) {
  const src = path.join(SFX_DIR, srcName);
  const dst = path.join(SFX_DIR, dstName);
  if (fs.existsSync(src)) {
    fs.copyFileSync(src, dst);
    console.log(`[COPIED] ${dstName} (${fs.statSync(dst).size} bytes)`);
  }
}

// Helper: Write 44.1kHz 16-bit Mono RIFF WAV
const SR = 44100;
function writeWav(filename, durationSec, sampleFn) {
  const numSamples = Math.floor(SR * durationSec);
  const dataSize = numSamples * 2;
  const buf = Buffer.alloc(44 + dataSize);

  buf.write("RIFF", 0);
  buf.writeUInt32LE(36 + dataSize, 4);
  buf.write("WAVE", 8);
  buf.write("fmt ", 12);
  buf.writeUInt32LE(16, 16);      // PCM chunk size
  buf.writeUInt16LE(1, 20);       // PCM = 1
  buf.writeUInt16LE(1, 22);       // Mono = 1
  buf.writeUInt32LE(SR, 24);      // Sample rate
  buf.writeUInt32LE(SR * 2, 28);  // Byte rate
  buf.writeUInt16LE(2, 32);       // Block align
  buf.writeUInt16LE(16, 34);      // Bits per sample
  buf.write("data", 36);
  buf.writeUInt32LE(dataSize, 40);

  // Deterministic PRNG for clean repeatable noise
  let seed = 0x13579bdf;
  const rand = () => {
    seed = (seed * 1664525 + 1013904223) >>> 0;
    return (seed / 0xffffffff) * 2 - 1;
  };

  let lp = 0;
  for (let i = 0; i < numSamples; i++) {
    const t = i / SR;
    let s = sampleFn(t, durationSec, rand, (x, alpha) => {
      lp += alpha * (x - lp);
      return lp;
    });
    // Soft clip limiter
    s = Math.tanh(s * 1.15);
    const pcm = Math.max(-32768, Math.min(32767, Math.round(s * 31000)));
    buf.writeInt16LE(pcm, 44 + i * 2);
  }

  const outPath = path.join(SFX_DIR, filename);
  fs.writeFileSync(outPath, buf);
  console.log(`[SYNTH] ${filename} (${buf.length} bytes)`);
}

// 1. corte_lamina.wav — Crisp metallic blade slash (Falcata / Gladius / Szabla)
writeWav("corte_lamina.wav", 0.34, (t, dur, rand, lpf) => {
  const env = Math.exp(-t * 14) * Math.min(1, t / 0.008);
  const whoosh = lpf(rand(), 0.28) * Math.exp(-Math.pow((t - 0.07) / 0.09, 2)) * 0.85;
  const ring = (
    Math.sin(2 * Math.PI * (2450 - t * 900) * t) * 0.35 +
    Math.sin(2 * Math.PI * 3890 * t + Math.sin(2 * Math.PI * 620 * t) * 1.6) * 0.25 +
    Math.sin(2 * Math.PI * 5420 * t) * 0.15
  ) * env;
  return whoosh + ring;
});

// 2. impacto_macico_pedra.wav — Heavy granite crush & sub impact (Endovelico / Bracaro)
writeWav("impacto_macico_pedra.wav", 0.52, (t, _d, rand, lpf) => {
  const subEnv = Math.exp(-t * 8.5);
  const sub = Math.sin(2 * Math.PI * (125 * Math.exp(-t * 9) + 38) * t) * subEnv * 1.1;
  const crack = lpf(rand(), 0.16) * Math.exp(-t * 15) * 0.9;
  const grit = (t > 0.04 && t < 0.22 ? rand() * Math.exp(-(t - 0.04) * 18) * 0.4 : 0);
  return sub + crack + grit;
});

// 3. carnyx_trombeta_gaulesa.wav — Bronze boar-head Gallic Carnyx war-horn blast (Breno)
writeWav("carnyx_trombeta_gaulesa.wav", 0.95, (t, dur, rand, lpf) => {
  const attack = Math.min(1, t / 0.05);
  const release = t > dur - 0.18 ? Math.max(0, (dur - t) / 0.18) : 1;
  const env = attack * release;
  const vibrato = Math.sin(2 * Math.PI * 6.2 * t) * 2.5;
  const f0 = (t < 0.12 ? 146.8 + (t / 0.12) * 49.2 : 196.0) + vibrato; // D3 -> G3 brass slide
  let brass = 0;
  const amps = [0.50, 0.42, 0.34, 0.26, 0.20, 0.14, 0.09, 0.06];
  for (let h = 1; h <= amps.length; h++) {
    brass += Math.sin(2 * Math.PI * (f0 * h) * t + Math.sin(2 * Math.PI * f0 * t) * 0.45) * amps[h - 1];
  }
  const breath = lpf(rand(), 0.18) * 0.12 * env;
  return (brass * 0.55 + breath) * env;
});

// 4. trovao_eslavo_perun.wav — Slavic Perun lightning crackle + frost crystal chime (Klaudia)
writeWav("trovao_eslavo_perun.wav", 0.68, (t, _d, rand, lpf) => {
  const zapGate = Math.sin(t * 170) > 0.25 ? 1.0 : 0.35;
  const bolt = lpf(rand(), 0.55) * Math.exp(-t * 6.5) * zapGate * 0.75;
  const arc = Math.sin(2 * Math.PI * (1600 + Math.sin(t * 95) * 700) * t) * Math.exp(-t * 11) * 0.35;
  const frost = (
    Math.sin(2 * Math.PI * 3520 * t) * 0.22 +
    Math.sin(2 * Math.PI * 4698 * t) * 0.18 +
    Math.sin(2 * Math.PI * 6272 * t) * 0.12
  ) * Math.exp(-Math.max(0, t - 0.06) * 7.5);
  return bolt + arc + frost;
});

// 5. rasteira_poeira.wav — Low sweep kick + gravel slide
writeWav("rasteira_poeira.wav", 0.36, (t, _d, rand, lpf) => {
  const swoosh = lpf(rand(), 0.12) * Math.exp(-Math.pow((t - 0.09) / 0.11, 2)) * 0.95;
  const thump = Math.sin(2 * Math.PI * (150 * Math.exp(-t * 14) + 45) * t) * Math.exp(-t * 16) * 0.65;
  return swoosh + thump;
});

// 6. agarrao_trava.wav — Classic 2D fighting game throw grab / cloth lock
writeWav("agarrao_trava.wav", 0.26, (t, _d, rand, lpf) => {
  const cloth = lpf(rand(), 0.25) * Math.exp(-t * 22) * 0.75;
  const lock1 = Math.sin(2 * Math.PI * (240 * Math.exp(-t * 20) + 70) * t) * Math.exp(-t * 18) * 0.85;
  const lock2 = t > 0.055 ? Math.sin(2 * Math.PI * 155 * (t - 0.055)) * Math.exp(-(t - 0.055) * 24) * 0.7 : 0;
  return cloth + lock1 + lock2;
});

// 7. counter_hit_bell.wav — Dramatic Arcade Counter-Hit FM sting + heavy punch
writeWav("counter_hit_bell.wav", 0.58, (t, _d, rand, lpf) => {
  const punch = Math.sin(2 * Math.PI * (210 * Math.exp(-t * 16) + 48) * t) * Math.exp(-t * 11) * 0.9;
  const snap = lpf(rand(), 0.4) * Math.exp(-t * 28) * 0.6;
  const mod = Math.sin(2 * Math.PI * 1244.5 * t) * 2.4 * Math.exp(-t * 7);
  const bell = (
    Math.sin(2 * Math.PI * 880 * t + mod) * 0.45 +
    Math.sin(2 * Math.PI * 1318.5 * t + mod * 0.7) * 0.32
  ) * Math.exp(-t * 5.2);
  return punch + snap + bell;
});

// 8. guard_crush.wav — Guard break / shield shatter
writeWav("guard_crush.wav", 0.50, (t, _d, rand, lpf) => {
  const smash = lpf(rand(), 0.48) * Math.exp(-t * 9) * 0.85;
  const shards = (
    Math.sin(2 * Math.PI * 1975 * t + rand() * 0.3) * 0.3 +
    Math.sin(2 * Math.PI * 2840 * t) * 0.25 +
    Math.sin(2 * Math.PI * 4120 * t) * 0.2
  ) * Math.exp(-t * 10);
  const boom = Math.sin(2 * Math.PI * (160 * Math.exp(-t * 10) + 42) * t) * Math.exp(-t * 9) * 0.8;
  return smash + shards + boom;
});

// 9. aterragem_arena.wav — Heavy fighter boot landing on granite flagstones
writeWav("aterragem_arena.wav", 0.22, (t, _d, rand, lpf) => {
  const step = Math.sin(2 * Math.PI * (135 * Math.exp(-t * 22) + 46) * t) * Math.exp(-t * 20) * 0.85;
  const grit = lpf(rand(), 0.14) * Math.exp(-t * 26) * 0.55;
  return step + grit;
});

// 10. cursor_selecao_lutador.wav — Crisp CPS2 character select cursor tick
writeWav("cursor_selecao_lutador.wav", 0.09, (t) => {
  const f = t < 0.03 ? 1046.5 : 1567.98; // C6 -> G6 arcade blip
  return (Math.sin(2 * Math.PI * f * t) * 0.65 + Math.sign(Math.sin(2 * Math.PI * f * t)) * 0.18) * Math.exp(-t * 32);
});

// 11. confirmar_lutador_gongo.wav — Bronze gong + flame lock-in on fighter confirm
writeWav("confirmar_lutador_gongo.wav", 0.85, (t, _d, rand, lpf) => {
  const mod = Math.sin(2 * Math.PI * 311.1 * t) * 3.1 * Math.exp(-t * 4.5);
  const gong = (
    Math.sin(2 * Math.PI * 220 * t + mod) * 0.55 +
    Math.sin(2 * Math.PI * 440 * t + mod * 0.6) * 0.30 +
    Math.sin(2 * Math.PI * 659.25 * t) * 0.22
  ) * Math.exp(-t * 3.4);
  const flame = lpf(rand(), 0.22) * Math.exp(-t * 7.5) * 0.4;
  return gong + flame;
});

// 12. timer_10s_alerta.wav — Urgent arcade 10-second timer warning beep
writeWav("timer_10s_alerta.wav", 0.20, (t) => {
  const gate = (t < 0.08 || (t > 0.10 && t < 0.18)) ? 1 : 0;
  const tone = Math.sin(2 * Math.PI * 987.77 * t) * 0.6 + Math.sin(2 * Math.PI * 1975.5 * t) * 0.25;
  return tone * gate * Math.exp(-(t % 0.10) * 12);
});

// 13. frasco_alquimico_explosao.wav — Glass potion vial shatter + emerald Greek-fire whoosh (Marco)
writeWav("frasco_alquimico_explosao.wav", 0.66, (t, _d, rand, lpf) => {
  const glass = (
    Math.sin(2 * Math.PI * 4180 * t) * 0.28 +
    Math.sin(2 * Math.PI * 5640 * t) * 0.22 +
    Math.sin(2 * Math.PI * 7320 * t) * 0.16 +
    rand() * 0.35
  ) * Math.exp(-t * 28);
  const fire = lpf(rand(), 0.19) * Math.exp(-Math.pow((t - 0.16) / 0.19, 2)) * 0.95;
  const sub = Math.sin(2 * Math.PI * (145 * Math.exp(-t * 8) + 42) * t) * Math.exp(-Math.max(0, t - 0.03) * 7.5) * 0.75;
  return glass + fire + sub;
});

// 14. torcida_arena_reacao.wav — Warm medieval arena crowd roar + clashing shields/mugs
writeWav("torcida_arena_reacao.wav", 1.35, (t, dur, rand, lpf) => {
  const env = Math.min(1, t / 0.14) * (t > dur - 0.35 ? Math.max(0, (dur - t) / 0.35) : 1);
  const murmur = lpf(rand(), 0.09) * (0.65 + 0.25 * Math.sin(2 * Math.PI * 5.5 * t));
  const claps = (Math.sin(2 * Math.PI * 9.2 * t) > 0.78 ? rand() * 0.35 : 0);
  const horn = Math.sin(2 * Math.PI * 293.66 * t) * 0.12 * Math.exp(-Math.abs(t - 0.45) * 5);
  return (murmur + claps + horn) * env;
});

console.log("All 17 fighting SFX ready in Assets/Audio/SFX!");
