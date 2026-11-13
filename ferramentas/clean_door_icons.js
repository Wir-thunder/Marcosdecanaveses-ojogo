const fs = require('fs');
const files = ['Cenas/cena_principal.tscn', 'Cenas/Dungeon.tscn', 'Cenas/Floresta.tscn', 'Cenas/Taverna.tscn'];
for (const f of files) {
    if (!fs.existsSync(f)) continue;
    let txt = fs.readFileSync(f, 'utf8');
    txt = txt.replace(/icone_simbolo = "[^"]*"/g, 'icone_simbolo = "🏛️"');
    fs.writeFileSync(f, txt, 'utf8');
    console.log('Cleaned icone_simbolo in:', f);
}

