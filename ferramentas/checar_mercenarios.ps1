Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("$PSScriptRoot\..\Assets\Characters\Taverna\mercenarios_sentados.png")
for ($f = 0; $f -lt 8; $f++) {
    $minY = 999; $maxY = 0; $minX = 999; $maxX = 0
    for ($y = 0; $y -lt 144; $y++) {
        for ($x = $f*128; $x -lt ($f+1)*128; $x++) {
            $c = $bmp.GetPixel($x, $y)
            if ($c.A -gt 20) {
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
                $localX = $x - ($f * 128)
                if ($localX -lt $minX) { $minX = $localX }
                if ($localX -gt $maxX) { $maxX = $localX }
            }
        }
    }
    Write-Host ("Frame {0}: X=[{1},{2}] Y=[{3},{4}] Width={5} Height={6}" -f $f, $minX, $maxX, $minY, $maxY, ($maxX - $minX + 1), ($maxY - $minY + 1))
}
$bmp.Dispose()

