Add-Type -AssemblyName System.Drawing

$root = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo"
$srcBg = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\alchemy_shop_interior_1793624949238.jpg"
$srcFurn = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\alchemy_shop_furniture_spritesheet_1793624960765.jpg"

Copy-Item $srcBg "$root\Assets\Source\raw\ai\loja_cenario_raw.jpg" -Force
Copy-Item $srcFurn "$root\Assets\Source\raw\ai\loja_moveis_raw.jpg" -Force

# 1. Process Background to 640x360
$bmpBg = [System.Drawing.Bitmap]::new($srcBg)
$finalBg = New-Object System.Drawing.Bitmap(640, 360, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($finalBg)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($bmpBg, 0, 0, 640, 360)
$g.Dispose()
$bmpBg.Dispose()

$destBg = "$root\Assets\Environment\backgrounds\loja_cenario.png"
$finalBg.Save($destBg, [System.Drawing.Imaging.ImageFormat]::Png)
$finalBg.Dispose()
Write-Output "Saved background: $destBg (640x360)"

# 2. Slice Furniture from 1024x1024 sheet (2x2 grid)
$bmpFurn = [System.Drawing.Bitmap]::new($srcFurn)

function Crop-Furniture($bmp, $x0, $y0, $x1, $y1, $destPath, $targetW = 0, $targetH = 0) {
    $minX = $x1; $maxX = $x0; $minY = $y1; $maxY = $y0
    for ($y = $y0; $y -le $y1; $y++) {
        for ($x = $x0; $x -le $x1; $x++) {
            $p = $bmp.GetPixel($x, $y)
            if ($p.R -lt 238 -or $p.G -lt 238 -or $p.B -lt 238) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($minX -ge $maxX -or $minY -ge $maxY) {
        Write-Warning "No content in region ($x0,$y0)-($x1,$y1)"
        return
    }

    $pad = 2
    $minX = [Math]::Max($x0, $minX - $pad)
    $minY = [Math]::Max($y0, $minY - $pad)
    $maxX = [Math]::Min($x1, $maxX + $pad)
    $maxY = [Math]::Min($y1, $maxY + $pad)

    $cropW = $maxX - $minX + 1
    $cropH = $maxY - $minY + 1

    $cropped = New-Object System.Drawing.Bitmap($cropW, $cropH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    for ($cy = 0; $cy -lt $cropH; $cy++) {
        $sy = $minY + $cy
        for ($cx = 0; $cx -lt $cropW; $cx++) {
            $sx = $minX + $cx
            $p = $bmp.GetPixel($sx, $sy)

            $diffR = 255 - $p.R
            $diffG = 255 - $p.G
            $diffB = 255 - $p.B
            $dist = [Math]::Sqrt($diffR*$diffR + $diffG*$diffG + $diffB*$diffB)

            if ($dist -lt 14.0) {
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            } elseif ($dist -lt 36.0) {
                $alpha = [int]([Math]::Min(255.0, ($dist - 14.0) / 22.0 * 255.0))
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb($alpha, $p.R, $p.G, $p.B))
            } else {
                $cropped.SetPixel($cx, $cy, [System.Drawing.Color]::FromArgb(255, $p.R, $p.G, $p.B))
            }
        }
    }

    if ($targetW -gt 0 -and $targetH -gt 0) {
        $final = New-Object System.Drawing.Bitmap($targetW, $targetH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($final)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.DrawImage($cropped, 0, 0, $targetW, $targetH)
        $g.Dispose()
        $cropped.Dispose()
        $final.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $final.Dispose()
    } else {
        $cropped.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $cropped.Dispose()
    }

    Write-Output "Saved furniture: $destPath ($cropW x $cropH -> $(if ($targetW -gt 0) {$targetW} else {$cropW}) x $(if ($targetH -gt 0) {$targetH} else {$cropH}))"
}

# Top-Left: Balcao (target around 120x64 px for nice top-down proportions)
Crop-Furniture $bmpFurn 20 20 500 500 "$root\Assets\Environment\props\balcao.png" 110 56

# Top-Right: Caldeirao (target around 64x64 px)
Crop-Furniture $bmpFurn 520 20 1000 500 "$root\Assets\Environment\props\caldeirao.png" 64 64

# Bottom-Left: Prateleira de Pocoes (target around 64x80 px)
Crop-Furniture $bmpFurn 20 520 500 1000 "$root\Assets\Environment\props\prateleira.png" 64 76

# Bottom-Right: Banca Fornecedor (target around 80x56 px)
Crop-Furniture $bmpFurn 520 520 1000 1000 "$root\Assets\Environment\props\fornecedor_pixel.png" 80 56

$bmpFurn.Dispose()
Write-Output "Done creating all Shop Assets!"

