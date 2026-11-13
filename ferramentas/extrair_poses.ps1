Add-Type -AssemblyName System.Drawing
$src = [System.Drawing.Bitmap]::FromFile("$PSScriptRoot\..\Assets\Characters\Taverna\mercenarios_sentados.png")
$outDir = "$PSScriptRoot\..\scratch\taverna_poses"
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir | Out-Null }

for ($i = 0; $i -lt 8; $i++) {
    $rect = New-Object System.Drawing.Rectangle ($i * 128), 0, 128, 144
    $dest = New-Object System.Drawing.Bitmap 128, 144
    $g = [System.Drawing.Graphics]::FromImage($dest)
    $g.DrawImage($src, 0, 0, $rect, [System.Drawing.GraphicsUnit]::Pixel)
    $g.Dispose()
    $dest.Save("$outDir\pose_$i.png", [System.Drawing.Imaging.ImageFormat]::Png)
    $dest.Dispose()
}
$src.Dispose()
Write-Host "Extracted 8 poses to $outDir"

