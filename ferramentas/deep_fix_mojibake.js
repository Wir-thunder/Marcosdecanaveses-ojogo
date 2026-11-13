const fs = require('fs');
const path = require('path');

const rootDirs = [
    path.join(__dirname, '..', 'Cenas'),
    path.join(__dirname, '..', 'Scripts'),
    path.join(__dirname, '..', 'Recursos')
];

const patterns = [
    // Triple encoded
    [/Ãâ‚¬/g, 'À'],
    [/PRAÃâ€¡A/g, 'PRAÇA'],
    [/PraÃÂ§a/g, 'Praça'],
    [/granÃÂ­tica/g, 'granítica'],
    [/ÃÂ /g, 'à'],
    [/minÃÂ©rios/g, 'minérios'],
    [/Ã°Å¸Â â€ºÃ¯Â¸Â /g, '🏛️'],
    [/Ã°Å¸Â â€º/g, '🏛️'],
    [/Ã¢â‚¬â„¢/g, "'"],
    [/Ã¢â‚¬â€œ/g, "—"],
    [/Ã¢â‚¬â€/g, "—"],

    // Double encoded
    [/Ã\u00A0/g, 'à'],
    [/Ã¡/g, 'á'],
    [/Ã¢/g, 'â'],
    [/Ã£/g, 'ã'],
    [/Ã©/g, 'é'],
    [/Ãª/g, 'ê'],
    [/Ã\u00AD/g, 'í'],
    [/Ã­/g, 'í'],
    [/Ã³/g, 'ó'],
    [/Ã´/g, 'ô'],
    [/Ãµ/g, 'õ'],
    [/Ãº/g, 'ú'],
    [/Ã§/g, 'ç'],
    [/Ã/g, 'Á'],
    [/Ã€/g, 'À'],
    [/Ã‚/g, 'Â'],
    [/Ãƒ/g, 'Ã'],
    [/Ã‰/g, 'É'],
    [/ÃŠ/g, 'Ê'],
    [/Ã\u008D/g, 'Í'],
    [/Ã“/g, 'Ó'],
    [/Ã”/g, 'Ô'],
    [/Ã•/g, 'Õ'],
    [/Ãš/g, 'Ú'],
    [/Ã‡/g, 'Ç'],
    [/Â·/g, '·'],
    [/Â/g, ''] // Clean leftover solitary Â
];

function walk(dir, callback) {
    if (!fs.existsSync(dir)) return;
    for (const f of fs.readdirSync(dir)) {
        const full = path.join(dir, f);
        const stat = fs.statSync(full);
        if (stat.isDirectory()) walk(full, callback);
        else if (/\.(tscn|gd|tres)$/.test(f)) callback(full);
    }
}

let count = 0;
for (const dir of rootDirs) {
    walk(dir, (file) => {
        let text = fs.readFileSync(file, 'utf8');
        let orig = text;
        for (const [regex, rep] of patterns) {
            text = text.replace(regex, rep);
        }
        if (text !== orig) {
            fs.writeFileSync(file, text, 'utf8');
            console.log('Deep cleaned:', path.basename(file));
            count++;
        }
    });
}
console.log(`Deep cleaned ${count} files.`);

