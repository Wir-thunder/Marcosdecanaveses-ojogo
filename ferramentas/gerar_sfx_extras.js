const fs = require('fs');
const path = require('path');

function createWavHeader(numSamples, sampleRate = 44100, numChannels = 1, bitsPerSample = 16) {
    const byteRate = sampleRate * numChannels * (bitsPerSample / 8);
    const blockAlign = numChannels * (bitsPerSample / 8);
    const dataSize = numSamples * numChannels * (bitsPerSample / 8);
    const buffer = Buffer.alloc(44);

    buffer.write("RIFF", 0);
    buffer.writeUInt32LE(36 + dataSize, 4);
    buffer.write("WAVE", 8);
    buffer.write("fmt ", 12);
    buffer.writeUInt32LE(16, 16);
    buffer.writeUInt16LE(1, 20); // PCM
    buffer.writeUInt16LE(numChannels, 22);
    buffer.writeUInt32LE(sampleRate, 24);
    buffer.writeUInt32LE(byteRate, 28);
    buffer.writeUInt16LE(blockAlign, 32);
    buffer.writeUInt16LE(bitsPerSample, 34);
    buffer.write("data", 36);
    buffer.writeUInt32LE(dataSize, 40);

    return buffer;
}

function saveWav(filename, samples, sampleRate = 44100) {
    const header = createWavHeader(samples.length, sampleRate);
    const data = Buffer.alloc(samples.length * 2);
    for (let i = 0; i < samples.length; i++) {
        const val = Math.max(-1, Math.min(1, samples[i]));
        const s16 = Math.floor(val < 0 ? val * 0x8000 : val * 0x7FFF);
        data.writeInt16LE(s16, i * 2);
    }
    const full = Buffer.concat([header, data]);
    fs.writeFileSync(filename, full);
    console.log(`Saved ${filename}`);
}

const outDir = path.join(__dirname, '..', 'Assets', 'Audio', 'SFX');

// 1. Golpe no Ar (Whoosh / Whiff)
{
    const sampleRate = 44100;
    const dur = 0.22;
    const numSamples = Math.floor(dur * sampleRate);
    const samples = new Float32Array(numSamples);
    for (let i = 0; i < numSamples; i++) {
        const t = i / sampleRate;
        const env = Math.sin((t / dur) * Math.PI) * Math.exp(-t * 8.0);
        const freq = 380 - (t / dur) * 260; // 380Hz down to 120Hz
        const sine = Math.sin(2 * Math.PI * freq * t);
        const noise = (Math.random() * 2 - 1) * 0.45;
        samples[i] = (sine * 0.55 + noise) * env * 0.75;
    }
    saveWav(path.join(outDir, 'golpe_ar.wav'), samples);
}

// 2. Disparo Especial (Hadouken launch surge)
{
    const sampleRate = 44100;
    const dur = 0.45;
    const numSamples = Math.floor(dur * sampleRate);
    const samples = new Float32Array(numSamples);
    for (let i = 0; i < numSamples; i++) {
        const t = i / sampleRate;
        const env = Math.sin(Math.min(1, t / 0.05) * Math.PI * 0.5) * Math.exp(-t * 4.5);
        const f1 = 180 + Math.sin(t * 40) * 40 + t * 650; // Rising energy pitch
        const f2 = 90 + t * 300;
        const s1 = Math.sin(2 * Math.PI * f1 * t);
        const s2 = Math.sin(2 * Math.PI * f2 * t);
        const noise = (Math.random() * 2 - 1) * 0.25;
        samples[i] = (s1 * 0.45 + s2 * 0.35 + noise) * env * 0.85;
    }
    saveWav(path.join(outDir, 'especial_disparo.wav'), samples);
}

// 3. Fanfarra de Vitória (Torneio Tongobriga Campeão)
{
    const sampleRate = 44100;
    const dur = 2.2;
    const numSamples = Math.floor(dur * sampleRate);
    const samples = new Float32Array(numSamples);
    // Notes: C4 (261.6), E4 (329.6), G4 (392.0), C5 (523.2), E5 (659.3)
    const notes = [
        { start: 0.00, end: 0.22, freq: 261.63 },
        { start: 0.22, end: 0.44, freq: 329.63 },
        { start: 0.44, end: 0.70, freq: 392.00 },
        { start: 0.70, end: 1.05, freq: 523.25 },
        { start: 1.05, end: 2.10, freq: 659.25 }
    ];
    for (let i = 0; i < numSamples; i++) {
        const t = i / sampleRate;
        let val = 0;
        for (const n of notes) {
            if (t >= n.start && t < n.end) {
                const noteT = t - n.start;
                const noteDur = n.end - n.start;
                const env = Math.sin(Math.min(1, noteT / 0.02) * Math.PI * 0.5) * (1.0 - noteT / noteDur);
                // Brass/chime harmonic rich wave
                const s1 = Math.sin(2 * Math.PI * n.freq * noteT);
                const s2 = Math.sin(2 * Math.PI * n.freq * 2 * noteT) * 0.4;
                const s3 = Math.sin(2 * Math.PI * n.freq * 3 * noteT) * 0.2;
                val += (s1 + s2 + s3) * env * 0.35;
            }
        }
        samples[i] = val;
    }
    saveWav(path.join(outDir, 'fanfarra_vitoria.wav'), samples);
}
console.log("All audio generated successfully!");

