Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::new("C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\boar_forest_spritesheet_1793624127423.jpg")
$w = $bmp.Width
for ($x = 50; $x -lt $w; $x += 25) {
    $dark = 0
    for ($y = 420; $y -lt 700; $y += 5) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -lt 240 -or $c.G -lt 240 -or $c.B -lt 240) { $dark++ }
    }
    Write-Output "X=$($x) dark=$($dark)"
}
$bmp.Dispose()
