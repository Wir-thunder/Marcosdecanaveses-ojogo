const fs = require('fs');
const path = require('path');

function replaceInFile(filePath, searchStr, replaceStr) {
    const fullPath = path.resolve(__dirname, '..', filePath);
    let content = fs.readFileSync(fullPath, 'utf8');
    const normSearch = searchStr.replace(/\r\n/g, '\n');
    const normContent = content.replace(/\r\n/g, '\n');
    
    if (!normContent.includes(normSearch)) {
        console.error(`Target not found in ${filePath}`);
        return false;
    }
    const updated = normContent.replace(normSearch, replaceStr.replace(/\r\n/g, '\n'));
    fs.writeFileSync(fullPath, updated, 'utf8');
    console.log(`Updated ${filePath}`);
    return true;
}

replaceInFile(
    'Scripts/PainelAtendimentoBalcao.gd',
    'func _ao_alternar_sugestoes() -> void:\n\tcontainer_sugestoes.visible = not container_sugestoes.visible',
    'func _ao_alternar_sugestoes() -> void:\n\tAudioManager.tocar_sfx("ui_click")\n\tcontainer_sugestoes.visible = not container_sugestoes.visible'
);

replaceInFile(
    'Scripts/PainelAtendimentoBalcao.gd',
    'func _ao_dispensar() -> void:\n\tif cliente_atual != null:',
    'func _ao_dispensar() -> void:\n\tAudioManager.tocar_sfx("ui_click")\n\tif cliente_atual != null:'
);

console.log("Completed PainelAtendimentoBalcao hook!");
