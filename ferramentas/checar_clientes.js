const fs = require('fs');

function checkPng(file) {
    const buf = fs.readFileSync(file);
    const w = buf.readUInt32BE(16);
    const h = buf.readUInt32BE(20);
    console.log(file, w, 'x', h);
}

for (let i = 0; i < 4; i++) {
    checkPng(`Assets/Characters/Clientes/cliente_${i}/walk_down_1.png`);
}

