const fs = require('fs');
const path = require('path');

const rootDirs = [
    path.join(__dirname, '..', 'Cenas'),
    path.join(__dirname, '..', 'Scripts'),
    path.join(__dirname, '..', 'Recursos')
];

const replacements = [
    // Background path repair
    ['res://Sprites/CenÃ¡rio_loja.jpeg', 'res://Assets/Environment/backgrounds/loja_cenario.png'],
    ['res://Sprites/Cenário_loja.jpeg', 'res://Assets/Environment/backgrounds/loja_cenario.png'],
    ['res://Sprites/BalcÃ£o_loja_alquimista.jpeg', 'res://Assets/Environment/props/balcao.png'],
    ['res://Sprites/Balcão_loja_alquimista.jpeg', 'res://Assets/Environment/props/balcao.png'],
    ['res://Sprites/CaldeirÃ£o.jpeg', 'res://Assets/Environment/props/caldeirao.png'],
    ['res://Sprites/Caldeirão.jpeg', 'res://Assets/Environment/props/caldeirao.png'],
    
    // Corrupted Portuguese Accents
    ['Ã¡', 'á'],
    ['Ã ', 'à'],
    ['Ã¢', 'â'],
    ['Ã£', 'ã'],
    ['Ã©', 'é'],
    ['Ãª', 'ê'],
    ['Ã­', 'í'],
    ['Ã³', 'ó'],
    ['Ã´', 'ô'],
    ['Ãµ', 'õ'],
    ['Ãº', 'ú'],
    ['Ã§', 'ç'],
    ['Ã', 'Á'],
    ['Ã€', 'À'],
    ['Ã‚', 'Â'],
    ['Ãƒ', 'Ã'],
    ['Ã‰', 'É'],
    ['ÃŠ', 'Ê'],
    ['Ã', 'Í'],
    ['Ã“', 'Ó'],
    ['Ã”', 'Ô'],
    ['Ã•', 'Õ'],
    ['Ãš', 'Ú'],
    ['Ã‡', 'Ç'],

    // Corrupted Emojis & Symbols
    ['ðŸ ›ï¸ ', '🏛️'],
    ['ðŸ ›', '🏛️'],
    ['ðŸ§ª', '🧪'],
    ['ðŸŒ¿', '🌿'],
    ['âš”ï¸ ', '⚔️'],
    ['âš”', '⚔️'],
    ['ðŸ º', '🍺'],
    ['â˜…', '★'],
    ['ðŸ’¥', '💥'],
    ['ðŸ›¡ï¸ ', '🛡️'],
    ['ðŸ’Ž', '💎'],
    ['ðŸ’°', '💰'],
    ['â–¼', '▼'],
    ['â–²', '▲'],
    ['â–¶', '▶'],
    ['â–', '■']
];

function walk(dir, callback) {
    if (!fs.existsSync(dir)) return;
    const files = fs.readdirSync(dir);
    for (const f of files) {
        const full = path.join(dir, f);
        const stat = fs.statSync(full);
        if (stat.isDirectory()) {
            walk(full, callback);
        } else if (/\.(tscn|gd|tres)$/.test(f)) {
            callback(full);
        }
    }
}

let modifiedFiles = 0;
for (const dir of rootDirs) {
    walk(dir, (file) => {
        let text = fs.readFileSync(file, 'utf8');
        let changed = false;
        for (const [from, to] of replacements) {
            if (text.includes(from)) {
                text = text.split(from).join(to);
                changed = true;
            }
        }
        if (changed) {
            fs.writeFileSync(file, text, 'utf8');
            console.log('Fixed mojibake in:', path.basename(file));
            modifiedFiles++;
        }
    });
}

console.log(`Successfully fixed ${modifiedFiles} files!`);

