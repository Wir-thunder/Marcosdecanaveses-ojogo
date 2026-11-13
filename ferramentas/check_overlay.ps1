Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::new("c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Environment\overlays\praca_foreground.png")
$w = $bmp.Width
$h = $bmp.Height
Write-Output "Size: $w x $h"

# Check non-transparent pixels in overlay around the fountain (X: 340-420, Y: 180-260)
$fountainAlpha = 0
for ($y = 180; $y -lt 260; $y++) {
    for ($x = 340; $x -lt 420; $x++) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.A -gt 10) { $fountainAlpha++ }
    }
}
Write-Output "Alpha pixels around fountain in overlay: $fountainAlpha"

# Check other non-transparent pixels across whole image
$totalAlpha = 0
for ($y = 0; $y -lt $h; $y += 4) {
    for ($x = 0; $x -lt $w; $x += 4) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.A -gt 10) { $totalAlpha++ }
    }
}
Write-Output "Total non-transparent sample count: $totalAlpha"
$bmp.Dispose()

