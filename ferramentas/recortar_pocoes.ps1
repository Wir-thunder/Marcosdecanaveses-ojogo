Add-Type -AssemblyName System.Drawing

$src = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\magic_potions_spritesheet_1793624452526.jpg"
$destDir = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Icons\Potions"
Copy-Item $src "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Source\raw\pocoes_adicionais_raw.jpg" -Force

$bmp = [System.Drawing.Bitmap]::new($src)
$w = $bmp.Width
$h = $bmp.Height
Write-Output "Image size: $w x $h"

# Find 4 items along X axis
$inItem = $false
$startX = 0
$potions = @()

for ($x = 0; $x -lt $w; $x++) {
    $hasDark = $false
    for ($y = 20; $y -lt $h - 20; $y += 2) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.R -lt 238 -or $p.G -lt 238 -or $p.B -lt 238) {
            $hasDark = $true
            break
        }
    }
    if ($hasDark -and -not $inItem) {
        $inItem = $true
        $startX = $x
    } elseif (-not $hasDark -and $inItem) {
        if (($x - $startX) -gt 25) {
            $potions += [PSCustomObject]@{ X0 = $startX; X1 = $x }
            Write-Output "Potion found: X = $startX to $x (W = $($x - $startX))"
        }
        $inItem = $false
    }
}
if ($inItem -and (($w - $startX) -gt 25)) {
    $potions += [PSCustomObject]@{ X0 = $startX; X1 = $w }
    Write-Output "Potion found: X = $startX to $w (W = $($w - $startX))"
}

$names = @("pocao_fogo_do_paineiro", "pocao_sono_puro", "pocao_vida_fertil", "pocao_ascensao_dourada")

for ($i = 0; $i -lt [Math]::Min($names.Count, $potions.Count); $i++) {
    $p = $potions[$i]
    $name = $names[$i]
    $x0 = $p.X0; $x1 = $p.X1

    # find Y bounds
    $minY = $h; $maxY = 0
    for ($y = 10; $y -lt $h - 10; $y++) {
        for ($x = $x0; $x -le $x1; $x++) {
            $px = $bmp.GetPixel($x, $y)
            if ($px.R -lt 238 -or $px.G -lt 238 -or $px.B -lt 238) {
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    $pad = 2
    $minX = [Math]::Max(0, $x0 - $pad)
    $maxX = [Math]::Min($w - 1, $x1 + $pad)
    $minY = [Math]::Max(0, $minY - $pad)
    $maxY = [Math]::Min($h - 1, $maxY + $pad)

    $cropW = $maxX - $minX + 1
    $cropH = $maxY - $minY + 1

    $cropped = New-Object System.Drawing.Bitmap($cropW, $cropH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($cy = 0; $cy -lt $cropH; $cy++) {
        $sy = $minY + $cy
        for ($cx = 0; $cx -lt $cropW; $cx++) {
            $sx = $minX + $cx
            $pixel = $bmp.GetPixel($sx, $sy)

            $diffR = 255 - $pixel.R
            $diffG = 255 - $pixel.G
            $diffB = 255 - $pixel.B
            $dist = [Math]::Sqrt($diffR*$diffR + $diffG*$diffG + $diffB*$diffB)

            if ($dist -lt 14.0) {
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } elseif ($dist -lt 36.0) {
                $alpha = [int]([Math]::Min(255.0, ($dist - 14.0) / 22.0 * 255.0))
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb($alpha, $pixel.R, $pixel.G, $pixel.B))
            } else {
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb(255, $pixel.R, $pixel.G, $pixel.B))
            }
        }
    }

    $outBmp = New-Object System.Drawing.Bitmap(32, 32, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($outBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    
    # Keep aspect ratio inside 32x32
    $scale = [Math]::Min(30.0 / $cropW, 30.0 / $cropH)
    $drawW = [int]($cropW * $scale)
    $drawH = [int]($cropH * $scale)
    $drawX = [int]((32 - $drawW) / 2)
    $drawY = [int]((32 - $drawH) / 2)

    $g.DrawImage($cropped, $drawX, $drawY, $drawW, $drawH)
    $g.Dispose()
    $cropped.Dispose()

    $destPath = "$destDir\$name.png"
    $outBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $outBmp.Dispose()
    Write-Output "Saved: $destPath (32x32 PNG)"
}

$bmp.Dispose()
Write-Output "Done slicing potions!"

