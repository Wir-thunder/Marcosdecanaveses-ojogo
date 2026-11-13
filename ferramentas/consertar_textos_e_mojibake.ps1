$files = Get-ChildItem -Path "Cenas","Scripts" -Recurse -Include "*.tscn","*.gd"

$rep = [ordered]@{
    "CenÃ¡rio_loja.jpeg" = "loja_cenario.png"
    "Cenário_loja.jpeg"  = "loja_cenario.png"
    "Sprites/CenÃ¡rio_loja.jpeg" = "Assets/Environment/backgrounds/loja_cenario.png"
    "Sprites/Cenário_loja.jpeg"  = "Assets/Environment/backgrounds/loja_cenario.png"
    "Ã¡" = "á"
    "Ã " = "à"
    "Ã¢" = "â"
    "Ã£" = "ã"
    "Ã©" = "é"
    "Ãª" = "ê"
    "Ã­" = "í"
    "Ã³" = "ó"
    "Ã´" = "ô"
    "Ãµ" = "õ"
    "Ãº" = "ú"
    "Ã§" = "ç"
    "Ã" = "Á"
    "Ã€" = "À"
    "Ã‚" = "Â"
    "Ãƒ" = "Ã"
    "Ã‰" = "É"
    "ÃŠ" = "Ê"
    "Ã" = "Í"
    "Ã“" = "Ó"
    "Ã”" = "Ô"
    "Ã•" = "Õ"
    "Ãš" = "Ú"
    "Ã‡" = "Ç"
    "ðŸ ›ï¸ " = "🏛️"
    "ðŸ ›" = "🏛️"
    "ðŸ§ª" = "🧪"
    "ðŸŒ¿" = "🌿"
    "âš”ï¸ " = "⚔️"
    "âš”" = "⚔️"
    "ðŸ º" = "🍺"
    "â˜…" = "★"
    "ðŸ’¥" = "💥"
    "ðŸ›¡ï¸ " = "🛡️"
    "ðŸ’Ž" = "💎"
    "ðŸ’°" = "💰"
    "â–¼" = "▼"
    "â–²" = "▲"
    "â–¶" = "▶"
    "â–" = "■"
}

$fixedCount = 0
foreach ($f in $files) {
    $raw = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
    $modified = $false
    foreach ($k in $rep.Keys) {
        if ($raw.Contains($k)) {
            $raw = $raw.Replace($k, $rep[$k])
            $modified = $true
        }
    }
    if ($modified) {
        [System.IO.File]::WriteAllText($f.FullName, $raw, [System.Text.Encoding]::UTF8)
        Write-Output "Fixed: $($f.FullName)"
        $fixedCount++
    }
}

Write-Output "Total files fixed: $fixedCount"

