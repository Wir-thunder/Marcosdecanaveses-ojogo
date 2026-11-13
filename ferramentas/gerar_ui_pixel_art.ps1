Add-Type -AssemblyName System.Drawing

$destDir = "$PSScriptRoot\..\Assets\UI"
if (-not (Test-Path $destDir)) { New-Item -ItemType Directory -Path $destDir | Out-Null }

function ColorFromRGBA([int]$r, [int]$g, [int]$b, [int]$a = 255) {
    return [System.Drawing.Color]::FromArgb($a, $r, $g, $b)
}

$cTransp = [System.Drawing.Color]::Transparent
$cMadMuitoEscura = ColorFromRGBA 32 20 14
$cMadEscura       = ColorFromRGBA 52 34 22
$cMadMedia        = ColorFromRGBA 84 56 36
$cMadClara        = ColorFromRGBA 122 82 52
$cMadDestaque     = ColorFromRGBA 158 108 70
$cMadFundo        = ColorFromRGBA 42 28 18

$cFerroEscuro = ColorFromRGBA 24 24 26
$cFerroMedio  = ColorFromRGBA 48 50 54
$cFerroClaro  = ColorFromRGBA 88 92 98
$cLataoOuro   = ColorFromRGBA 198 152 58
$cLataoBrilho = ColorFromRGBA 240 205 110
$cLataoSombra = ColorFromRGBA 128 92 32

$cPergamEscuro = ColorFromRGBA 165 138 95
$cPergamMedio  = ColorFromRGBA 212 185 138
$cPergamClaro  = ColorFromRGBA 238 218 178
$cPergamBorda  = ColorFromRGBA 135 105 68

# 1. QUADRO DE MISSOES (520 x 330)
$w = 520; $h = 330
$bmpQuadro = New-Object System.Drawing.Bitmap $w, $h
$g = [System.Drawing.Graphics]::FromImage($bmpQuadro)
$g.Clear($cTransp)

# Sombra
$brShadow = New-Object System.Drawing.SolidBrush (ColorFromRGBA 0 0 0 110)
$g.FillRectangle($brShadow, 4, 4, $w - 4, $h - 4)

# Prancha de Fundo (Madeira)
$brMadFundo = New-Object System.Drawing.SolidBrush $cMadFundo
$g.FillRectangle($brMadFundo, 0, 0, $w - 5, $h - 5)

# Tábuas verticais
$penMuitoEscura = New-Object System.Drawing.Pen $cMadMuitoEscura, 2
$penMedia = New-Object System.Drawing.Pen $cMadMedia, 1
for ($tx = 0; $tx -lt ($w - 5); $tx += 52) {
    $g.DrawLine($penMuitoEscura, $tx, 0, $tx, $h - 5)
    for ($y = 8; $y -lt ($h - 12); $y += 14) {
        $ox = ($y * 7) % 36
        $g.DrawLine($penMedia, $tx + 4 + $ox, $y, $tx + 18 + $ox, $y)
    }
}

# Moldura Externa (14 px)
$borda = 14
$brMadEscura = New-Object System.Drawing.SolidBrush $cMadEscura
$g.FillRectangle($brMadEscura, 0, 0, $w - 5, $borda)
$g.FillRectangle($brMadEscura, 0, $h - 5 - $borda, $w - 5, $borda)
$g.FillRectangle($brMadEscura, 0, 0, $borda, $h - 5)
$g.FillRectangle($brMadEscura, $w - 5 - $borda, 0, $borda, $h - 5)

# Frisos da Moldura
$penDestaque = New-Object System.Drawing.Pen $cMadDestaque, 1
$penClara = New-Object System.Drawing.Pen $cMadClara, 1
$penEscura = New-Object System.Drawing.Pen $cMadMuitoEscura, 1
$g.DrawLine($penDestaque, 0, 0, $w - 5, 0)
$g.DrawLine($penClara, 1, 1, $w - 6, 1)
$g.DrawLine($penDestaque, 0, 0, 0, $h - 5)
$g.DrawLine($penClara, 1, 1, 1, $h - 6)

$g.DrawLine($penEscura, $borda, $borda, $w - 5 - $borda, $borda)
$g.DrawLine($penEscura, $borda, $borda, $borda, $h - 5 - $borda)
$g.DrawLine($penClara, $borda, $h - 5 - $borda, $w - 5 - $borda, $h - 5 - $borda)
$g.DrawLine($penClara, $w - 5 - $borda, $borda, $w - 5 - $borda, $h - 5 - $borda)

# Cantoneiras de Ferro Forjado e Rebites nos 4 cantos
$tamCanto = 30
$c1 = @(0, 0)
$c2 = @(($w - 5 - $tamCanto), 0)
$c3 = @(0, ($h - 5 - $tamCanto))
$c4 = @(($w - 5 - $tamCanto), ($h - 5 - $tamCanto))
$cantos = @($c1, $c2, $c3, $c4)
$brFerroMedio = New-Object System.Drawing.SolidBrush $cFerroMedio
$penFerroClaro = New-Object System.Drawing.Pen $cFerroClaro, 1
$penFerroEscuro = New-Object System.Drawing.Pen $cFerroEscuro, 1
$brLataoOuro = New-Object System.Drawing.SolidBrush $cLataoOuro

foreach ($c in $cantos) {
    $cx = $c[0]; $cy = $c[1]
    $g.FillRectangle($brFerroMedio, $cx + 2, $cy + 2, $tamCanto - 4, $tamCanto - 4)
    $g.DrawLine($penFerroClaro, $cx + 2, $cy + 2, $cx + $tamCanto - 2, $cy + 2)
    $g.DrawLine($penFerroClaro, $cx + 2, $cy + 2, $cx + 2, $cy + $tamCanto - 2)
    $g.DrawLine($penFerroEscuro, $cx + $tamCanto - 2, $cy + 2, $cx + $tamCanto - 2, $cy + $tamCanto - 2)
    $g.DrawLine($penFerroEscuro, $cx + 2, $cy + $tamCanto - 2, $cx + $tamCanto - 2, $cy + $tamCanto - 2)
    # Rebite central
    $g.FillRectangle($brLataoOuro, $cx + 12, $cy + 12, 6, 6)
}

# Placa Superior de Título Entalhada
$px1 = 110; $py1 = 6; $pw = $w - 225; $ph = 26
$brMadMedia = New-Object System.Drawing.SolidBrush $cMadMedia
$g.FillRectangle($brMadEscura, $px1, $py1, $pw, $ph)
$g.FillRectangle($brMadMedia, $px1 + 2, $py1 + 2, $pw - 4, $ph - 4)
$penLatao = New-Object System.Drawing.Pen $cLataoOuro, 1
$g.DrawRectangle($penLatao, $px1 + 1, $py1 + 1, $pw - 2, $ph - 2)

# Área Interna dos Contratos
$ix = 22; $iy = 38; $iw = $w - 49; $ih = $h - 56
$brInner = New-Object System.Drawing.SolidBrush (ColorFromRGBA 24 16 12 245)
$g.FillRectangle($brInner, $ix, $iy, $iw, $ih)
$g.DrawRectangle($penEscura, $ix, $iy, $iw, $ih)
$g.DrawRectangle($penMedia, $ix + 1, $iy + 1, $iw - 2, $ih - 2)

$g.Dispose()
$bmpQuadro.Save("$destDir\quadro_missoes_madeira.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmpQuadro.Dispose()
Write-Host "Gerado: quadro_missoes_madeira.png"

# 2. MOLDURA HUD PIXEL 9-SLICE (48 x 48)
$mw = 48; $mh = 48
$bmpHud = New-Object System.Drawing.Bitmap $mw, $mh
$gh = [System.Drawing.Graphics]::FromImage($bmpHud)
$gh.Clear($cTransp)

# Fundo translúcido escuro
$brHudBg = New-Object System.Drawing.SolidBrush (ColorFromRGBA 24 18 14 240)
$gh.FillRectangle($brHudBg, 5, 5, $mw - 10, $mh - 10)

# Moldura de carvalho entalhada
$penLataoBrilho = New-Object System.Drawing.Pen $cLataoBrilho, 1
$penLataoSombra = New-Object System.Drawing.Pen $cLataoSombra, 1
$gh.DrawRectangle($penLataoSombra, 0, 0, $mw - 1, $mh - 1)
$gh.DrawRectangle($penClara, 1, 1, $mw - 3, $mh - 3)
$gh.DrawRectangle($penMedia, 2, 2, $mw - 5, $mh - 5)
$gh.DrawRectangle($penEscura, 3, 3, $mw - 7, $mh - 7)
$gh.DrawRectangle($penLatao, 4, 4, $mw - 9, $mh - 9)

# Cantos reforçados
$h1 = @(0, 0)
$h2 = @(($mw - 4), 0)
$h3 = @(0, ($mh - 4))
$h4 = @(($mw - 4), ($mh - 4))
$cantosHud = @($h1, $h2, $h3, $h4)
foreach ($ch in $cantosHud) {
    $gh.FillRectangle($brLataoOuro, $ch[0], $ch[1], 4, 4)
}

$gh.Dispose()
$bmpHud.Save("$destDir\moldura_hud_pixel.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmpHud.Dispose()
Write-Host "Gerado: moldura_hud_pixel.png"

# 3. BOTOES DE MADEIRA (64 x 24)
function GerarBotao($nome, $corFundo, $corBordaTop, $corBordaBot, $corRebite) {
    $bw = 64; $bh = 24
    $bmpBtn = New-Object System.Drawing.Bitmap $bw, $bh
    $gb = [System.Drawing.Graphics]::FromImage($bmpBtn)
    $gb.Clear($cTransp)

    $brBg = New-Object System.Drawing.SolidBrush $corFundo
    $gb.FillRectangle($brBg, 1, 1, $bw - 2, $bh - 2)

    $penT = New-Object System.Drawing.Pen $corBordaTop, 1
    $penB = New-Object System.Drawing.Pen $corBordaBot, 1
    $gb.DrawLine($penT, 1, 1, $bw - 2, 1)
    $gb.DrawLine($penT, 1, 1, 1, $bh - 2)
    $gb.DrawLine($penB, 1, $bh - 2, $bw - 2, $bh - 2)
    $gb.DrawLine($penB, $bw - 2, 1, $bw - 2, $bh - 2)

    $brR = New-Object System.Drawing.SolidBrush $corRebite
    $gb.FillRectangle($brR, 3, 3, 2, 2)
    $gb.FillRectangle($brR, $bw - 5, 3, 2, 2)
    $gb.FillRectangle($brR, 3, $bh - 5, 2, 2)
    $gb.FillRectangle($brR, $bw - 5, $bh - 5, 2, 2)

    $gb.Dispose()
    $bmpBtn.Save("$destDir\$nome.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $bmpBtn.Dispose()
    Write-Host "Gerado: $nome.png"
}

GerarBotao "botao_madeira_normal" $cMadMedia $cMadClara $cMadMuitoEscura $cLataoOuro
GerarBotao "botao_madeira_hover" $cMadClara $cLataoBrilho $cMadEscura $cLataoBrilho
GerarBotao "botao_madeira_pressed" $cMadEscura $cMadMuitoEscura $cMadMedia $cLataoSombra

# 4. CARTAO DE PERGAMINHO (64 x 32)
$pw = 64; $ph = 32
$bmpP = New-Object System.Drawing.Bitmap $pw, $ph
$gp = [System.Drawing.Graphics]::FromImage($bmpP)
$gp.Clear($cTransp)

$brSh = New-Object System.Drawing.SolidBrush (ColorFromRGBA 0 0 0 60)
$gp.FillRectangle($brSh, 2, 2, $pw - 2, $ph - 2)

$brPg = New-Object System.Drawing.SolidBrush $cPergamMedio
$gp.FillRectangle($brPg, 0, 0, $pw - 3, $ph - 3)

$penP1 = New-Object System.Drawing.Pen $cPergamClaro, 1
$penP2 = New-Object System.Drawing.Pen $cPergamBorda, 1
$gp.DrawLine($penP1, 0, 0, $pw - 3, 0)
$gp.DrawLine($penP1, 0, 0, 0, $ph - 3)
$gp.DrawLine($penP2, 0, $ph - 3, $pw - 3, $ph - 3)
$gp.DrawLine($penP2, $pw - 3, 0, $pw - 3, $ph - 3)

$brSeal = New-Object System.Drawing.SolidBrush (ColorFromRGBA 180 50 40)
$gp.FillRectangle($brSeal, 3, 3, 3, 3)

$gp.Dispose()
$bmpP.Save("$destDir\pergaminho_card.png", [System.Drawing.Imaging.ImageFormat]::Png)
$bmpP.Dispose()
Write-Host "Gerado: pergaminho_card.png"

Write-Host "=== TODOS OS ASSETS DE UI EM PIXEL ART GERADOS COM SUCESSO! ==="
