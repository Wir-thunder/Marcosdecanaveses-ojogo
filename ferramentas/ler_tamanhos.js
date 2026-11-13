const fs = require('fs');
for (let file of ['mesa_central_mascarada.png', 'mesa_lateral_mascarada.png', 'balcao_taverna_mascarado.png', 'lareira_mascarada.png']) {
    const buf = fs.readFileSync('Assets/Environment/props_ysort/' + file);
    console.log(file, buf.readUInt32BE(16), 'x', buf.readUInt32BE(20));
}

