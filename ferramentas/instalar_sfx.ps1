$sfxDir = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Audio\SFX"

$map = @{
    "Aggressive_wild_boar_#1-1793632042252.mp3" = "javali_alerta.mp3"
    "Dramatic_heavy_cinem_#4-1793632360787.mp3" = "lutador_ko.mp3"
    "Fighting_game_super__#4-1793632253693.mp3" = "especial_pronto.mp3"
    "Heavy_medieval_woode_#2-1793631936449.mp3" = "porta_transicao.mp3"
    "Magical_potion_brewe_#3-1793631850587.mp3" = "pocao_pronta.mp3"
    "Medieval_fantasy_sho_#3-1793631724512.mp3" = "sino_porta.mp3"
    "Player_rustling_into_#4-1793632094682.mp3" = "moita_farfalhar.mp3"
    "Quick_cloth_swoosh_a_#4-1793632283424.mp3" = "lutador_pulo.mp3"
    "Short_subtle_wooden__#3-1793631999912.mp3" = "ui_click.mp3"
    "Super_satisfying_cri_#3-1793632145372.mp3" = "colheita_perfeita.mp3"
    "Twig_snapping_and_wi_#3-1793632179201.mp3" = "colheita_falha.mp3"
}

foreach ($item in $map.GetEnumerator()) {
    $src = Join-Path $sfxDir $item.Key
    $dst = Join-Path $sfxDir $item.Value
    if (Test-Path $src) {
        Copy-Item -Path $src -Destination $dst -Force
        Write-Host "Instalado: $($item.Key) -> $($item.Value)"
    } else {
        Write-Host "Nao encontrado: $($item.Key)"
    }
}

