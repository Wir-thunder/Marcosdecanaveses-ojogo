Add-Type -AssemblyName System.Drawing

$srcPath = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\special_projectiles_hit_fx_spritesheet_clean_1793630634732.jpg"
$outDir = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Effects\Tongobriga"

if (-not (Test-Path $outDir)) {
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null
}

$bmp = [System.Drawing.Bitmap]::FromFile($srcPath)
$w = $bmp.Width
$h = $bmp.Height
Write-Host "Spritesheet size: $w x $h"

function Export-RegionWithAlpha($x, $y, $rw, $rh, $destFile) {
    if ($x + $rw -gt $w) { $rw = $w - $x }
    if ($y + $rh -gt $h) { $rh = $h - $y }
    
    $cropped = New-Object System.Drawing.Bitmap($rw, $rh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    
    # 1. Aplicar máscara alfa com chave de preto suave
    for ($px = 0; $px -lt $rw; $px++) {
        for ($py = 0; $py -lt $rh; $py++) {
            $origPixel = $bmp.GetPixel($x + $px, $y + $py)
            $r = [int]$origPixel.R
            $g = [int]$origPixel.G
            $b = [int]$origPixel.B
            
            $maxC = [Math]::Max($r, [Math]::Max($g, $b))
            
            if ($maxC -lt 16) {
                $alpha = 0
            } elseif ($maxC -lt 45) {
                $alpha = [int](($maxC - 16) / 29.0 * 255.0)
            } else {
                $alpha = 255
            }
            
            if ($alpha -gt 0) {
                $cropped.SetPixel($px, $py, [System.Drawing.Color]::FromArgb($alpha, $r, $g, $b))
            } else {
                $cropped.SetPixel($px, $py, [System.Drawing.Color]::FromArgb(0, 0, 0, 0))
            }
        }
    }
    
    # 2. Localizar bounding box real dos pixels visíveis
    $minX = $rw; $maxX = 0; $minY = $rh; $maxY = 0
    $hasContent = $false
    for ($px = 0; $px -lt $rw; $px++) {
        for ($py = 0; $py -lt $rh; $py++) {
            $p = $cropped.GetPixel($px, $py)
            if ($p.A -gt 15) {
                $hasContent = $true
                if ($px -lt $minX) { $minX = $px }
                if ($px -gt $maxX) { $maxX = $px }
                if ($py -lt $minY) { $minY = $py }
                if ($py -gt $maxY) { $maxY = $py }
            }
        }
    }
    
    $fullDest = Join-Path $outDir $destFile
    if ($hasContent) {
        # Adicionar padding leve de 4px
        $pad = 4
        $bx = [Math]::Max(0, $minX - $pad)
        $by = [Math]::Max(0, $minY - $pad)
        $bw = [Math]::Min($rw - $bx, ($maxX - $minX + 1) + ($pad * 2))
        $bh = [Math]::Min($rh - $by, ($maxY - $minY + 1) + ($pad * 2))
        
        $trimmed = New-Object System.Drawing.Bitmap($bw, $bh, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $g = [System.Drawing.Graphics]::FromImage($trimmed)
        $srcRect = New-Object System.Drawing.Rectangle($bx, $by, $bw, $bh)
        $destRect = New-Object System.Drawing.Rectangle(0, 0, $bw, $bh)
        $g.DrawImage($cropped, $destRect, $srcRect, [System.Drawing.GraphicsUnit]::Pixel)
        $g.Dispose()
        
        $trimmed.Save($fullDest, [System.Drawing.Imaging.ImageFormat]::Png)
        $trimmed.Dispose()
        Write-Host "Exported trimmed ($bw x $bh): $destFile"
    } else {
        $cropped.Save($fullDest, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Host "Exported standard ($rw x $rh): $destFile"
    }
    
    $cropped.Dispose()
}

$topH = [int]($h * 0.49)
$bottomY = [int]($h * 0.50)
$bottomH = $h - $bottomY

$colW_top = [int]($w / 4)
Export-RegionWithAlpha 0 0 $colW_top $topH "especial_falcata_viriato.png"
Export-RegionWithAlpha $colW_top 0 $colW_top $topH "especial_flecha_nabia.png"
Export-RegionWithAlpha ($colW_top * 2) 0 $colW_top $topH "especial_fogo_endovelico.png"
Export-RegionWithAlpha ($colW_top * 3) 0 ($w - ($colW_top * 3)) $topH "especial_escudo_aunia.png"

$colW_bot = [int]($w / 3)
Export-RegionWithAlpha 0 $bottomY $colW_bot $bottomH "hitspark_soco.png"
Export-RegionWithAlpha $colW_bot $bottomY $colW_bot $bottomH "hitspark_critico.png"
Export-RegionWithAlpha ($colW_bot * 2) $bottomY ($w - ($colW_bot * 2)) $bottomH "hitspark_bloqueio.png"

$bmp.Dispose()
Write-Host "Completed perfectly!"
