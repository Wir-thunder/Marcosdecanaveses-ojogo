Add-Type -AssemblyName System.Drawing

function Analyze-Bands($path) {
    $bmp = [System.Drawing.Bitmap]::new($path)
    $w = $bmp.Width
    $h = $bmp.Height
    Write-Output "=== $path ==="

    foreach ($band in @(@{Name="Row1"; Y0=20; Y1=370}, @{Name="Row2"; Y0=380; Y1=750})) {
        Write-Output "--- $($band.Name) ---"
        $inSprite = $false
        $startX = 0
        $minY = 9999; $maxY = 0

        for ($x = 0; $x -lt $w; $x++) {
            $hasDark = $false
            for ($y = $band.Y0; $y -lt $band.Y1; $y += 2) {
                $c = $bmp.GetPixel($x, $y)
                if ($c.R -lt 240 -or $c.G -lt 240 -or $c.B -lt 240) {
                    $hasDark = $true
                    if ($y -lt $minY) { $minY = $y }
                    if ($y -gt $maxY) { $maxY = $y }
                }
            }

            if ($hasDark -and -not $inSprite) {
                $inSprite = $true
                $startX = $x
                $minY = 9999; $maxY = 0
            } elseif (-not $hasDark -and $inSprite) {
                # Require width > 15 to filter noise
                if (($x - $startX) -gt 15) {
                    Write-Output "Sprite found: X = $startX to $x (W = $($x - $startX)), Y = $minY to $maxY (H = $($maxY - $minY))"
                }
                $inSprite = $false
            }
        }
        if ($inSprite -and (($w - $startX) -gt 15)) {
            Write-Output "Sprite found: X = $startX to $w (W = $($w - $startX)), Y = $minY to $maxY (H = $($maxY - $minY))"
        }
    }
    $bmp.Dispose()
}

Analyze-Bands "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\boar_forest_spritesheet_1793624127423.jpg"
Analyze-Bands "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\spritesheet_mining_minecart_1793624130628.jpg"

