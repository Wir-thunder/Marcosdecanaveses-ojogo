Add-Type -AssemblyName System.Drawing

$root = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo"
$srcBoar = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\boar_forest_spritesheet_1793624127423.jpg"
$srcMine = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\spritesheet_mining_minecart_1793624130628.jpg"

# Ensure directories exist
$dirs = @(
    "$root\Assets\Source\raw",
    "$root\Assets\Characters\Monsters\Javali",
    "$root\Assets\Environment\props\mina_blocos",
    "$root\Assets\Environment\props\mina_carrinho",
    "$root\Assets\Icons\Ingredients",
    "$root\Assets\Icons\Potions"
)
foreach ($d in $dirs) {
    if (-not (Test-Path $d)) { New-Item -ItemType Directory -Path $d -Force | Out-Null }
}

Copy-Item $srcBoar "$root\Assets\Source\raw\javali_floresta_raw.jpg" -Force
Copy-Item $srcMine "$root\Assets\Source\raw\mina_carrinho_blocos_raw.jpg" -Force

function Crop-Transparent($srcBmp, $x0, $y0, $x1, $y1, $destPath, $targetWidth = 0, $targetHeight = 0) {
    # 1. Detect tight content box inside region
    $minX = $x1; $maxX = $x0; $minY = $y1; $maxY = $y0
    for ($y = $y0; $y -le $y1; $y++) {
        for ($x = $x0; $x -le $x1; $x++) {
            $p = $srcBmp.GetPixel($x, $y)
            if ($p.R -lt 238 -or $p.G -lt 238 -or $p.B -lt 238) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($minX -ge $maxX -or $minY -ge $maxY) {
        Write-Warning "No content found in region ($x0,$y0)-($x1,$y1)"
        return
    }

    # Add 2px padding
    $pad = 2
    $minX = [Math]::Max($x0, $minX - $pad)
    $minY = [Math]::Max($y0, $minY - $pad)
    $maxX = [Math]::Min($x1, $maxX + $pad)
    $maxY = [Math]::Min($y1, $maxY + $pad)

    $cropW = $maxX - $minX + 1
    $cropH = $maxY - $minY + 1

    $outW = if ($targetWidth -gt 0) { $targetWidth } else { $cropW }
    $outH = if ($targetHeight -gt 0) { $targetHeight } else { $cropH }

    $cropped = New-Object System.Drawing.Bitmap($cropW, $cropH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

    for ($cy = 0; $cy -lt $cropH; $cy++) {
        $sy = $minY + $cy
        for ($cx = 0; $cx -lt $cropW; $cx++) {
            $sx = $minX + $cx
            $p = $srcBmp.GetPixel($sx, $sy)

            # Chroma key white to transparent with edge smoothing
            $diffR = 255 - $p.R
            $diffG = 255 - $p.G
            $diffB = 255 - $p.B
            $dist = [Math]::Sqrt($diffR*$diffR + $diffG*$diffG + $diffB*$diffB)

            if ($dist -lt 14.0) {
                # Completely transparent
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } elseif ($dist -lt 36.0) {
                # Antialiased border
                $alpha = [int]([Math]::Min(255.0, ($dist - 14.0) / 22.0 * 255.0))
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B))
            } else {
                # Solid
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb(255, $p.R, $p.G, $p.B))
            }
        }
    }

    if ($targetWidth -gt 0 -and $targetHeight -gt 0) {
        $final = New-Object System.Drawing.Bitmap($targetWidth, $targetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($final)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($cropped, 0, 0, $targetWidth, $targetHeight)
        $g.Dispose()
        $cropped.Dispose()
        $final.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $final.Dispose()
    } else {
        $cropped.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $cropped.Dispose()
    }

    Write-Output "Saved: $destPath ($cropW x $cropH -> $outW x $outH)"
}

Write-Output "Processing Boar and Forest sprites..."
$bmpBoar = [System.Drawing.Bitmap]::new($srcBoar)

# Boar frames (Row 1)
Crop-Transparent $bmpBoar 42 45 285 370 "$root\Assets\Characters\Monsters\Javali\idle.png" 64 64
Crop-Transparent $bmpBoar 305 45 555 370 "$root\Assets\Characters\Monsters\Javali\walk_1.png" 64 64
Crop-Transparent $bmpBoar 570 45 825 370 "$root\Assets\Characters\Monsters\Javali\alert.png" 64 64
Crop-Transparent $bmpBoar 835 45 1090 370 "$root\Assets\Characters\Monsters\Javali\charge.png" 64 64
Crop-Transparent $bmpBoar 1095 45 1345 370 "$root\Assets\Characters\Monsters\Javali\stun.png" 64 64

# Main Javali sprite for game scene
Crop-Transparent $bmpBoar 305 45 555 370 "$root\Assets\Characters\Monsters\javali_selvagem.png" 64 64

# Forest props (Row 2)
Crop-Transparent $bmpBoar 100 420 400 720 "$root\Assets\Environment\props\moita_camuflagem.png" 80 80
Crop-Transparent $bmpBoar 480 420 660 720 "$root\Assets\Icons\Ingredients\erva_estrela.png" 48 48
Crop-Transparent $bmpBoar 750 420 945 720 "$root\Assets\Icons\Ingredients\cogumelo_luminescente.png" 48 48
Crop-Transparent $bmpBoar 1050 420 1280 720 "$root\Assets\Icons\Ingredients\raiz_ancestral.png" 48 48
$bmpBoar.Dispose()

Write-Output "Processing Mining and Minecart sprites..."
$bmpMine = [System.Drawing.Bitmap]::new($srcMine)

# Mining Blocks (Row 1)
Crop-Transparent $bmpMine 45 42 280 310 "$root\Assets\Environment\props\mina_blocos\bloco_terra.png" 48 48
Crop-Transparent $bmpMine 305 42 545 310 "$root\Assets\Environment\props\mina_blocos\bloco_granito.png" 48 48
Crop-Transparent $bmpMine 570 42 805 310 "$root\Assets\Environment\props\mina_blocos\bloco_veio_ouro.png" 48 48
Crop-Transparent $bmpMine 835 42 1070 310 "$root\Assets\Environment\props\mina_blocos\bloco_calcedonia.png" 48 48
Crop-Transparent $bmpMine 1095 42 1335 310 "$root\Assets\Environment\props\mina_blocos\bloco_basalto_fervente.png" 48 48

# Minecart Runner Props (Row 2)
Crop-Transparent $bmpMine 45 440 310 735 "$root\Assets\Environment\props\mina_carrinho\carrinho_run.png" 64 48
Crop-Transparent $bmpMine 320 375 600 630 "$root\Assets\Environment\props\mina_carrinho\carrinho_jump.png" 64 48
Crop-Transparent $bmpMine 625 490 895 735 "$root\Assets\Environment\props\mina_carrinho\carrinho_duck.png" 64 48
Crop-Transparent $bmpMine 910 410 1040 670 "$root\Assets\Environment\props\mina_carrinho\estalactite.png" 36 64
Crop-Transparent $bmpMine 1045 520 1340 725 "$root\Assets\Environment\props\mina_carrinho\trilho_quebrado.png" 64 32
$bmpMine.Dispose()

Write-Output "Done slicing and installing assets!"

