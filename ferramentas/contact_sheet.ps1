# contact_sheet.ps1 - gera uma previa com fundo axadrezado para confirmar transparencia.
param([string]$Pattern = '*.png')
Add-Type -AssemblyName System.Drawing
$root = Split-Path -Parent $PSScriptRoot
$dirs = @((Join-Path $root 'Assets\Icons\Ingredients'), (Join-Path $root 'Assets\Icons\Potions'))
$files = Get-ChildItem $dirs -File -Filter $Pattern | Sort-Object FullName
if ($files.Count -eq 0) { Write-Output 'nenhum PNG encontrado'; exit }
$cell = 160; $cols = 4
$rows = [int][math]::Ceiling($files.Count / $cols)
$fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
$sheet = New-Object System.Drawing.Bitmap(($cols*$cell), ($rows*$cell), $fmt)
$g = [System.Drawing.Graphics]::FromImage($sheet)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
for ($i=0; $i -lt $files.Count; $i++) {
    $cx = ($i % $cols) * $cell
    $cy = [int][math]::Floor($i / $cols) * $cell
    for ($yy=0; $yy -lt $cell; $yy+=16) {
        for ($xx=0; $xx -lt $cell; $xx+=16) {
            $shade = if ((([int][math]::Floor($xx/16)) + ([int][math]::Floor($yy/16))) % 2 -eq 0) { 90 } else { 150 }
            $brush = New-Object System.Drawing.SolidBrush([System.Drawing.Color]::FromArgb(255,$shade,$shade,$shade))
            $g.FillRectangle($brush, ($cx+$xx), ($cy+$yy), 16, 16)
            $brush.Dispose()
        }
    }
    $ic = New-Object System.Drawing.Bitmap($files[$i].FullName)
    $g.DrawImage($ic, ($cx + ($cell - $ic.Width)/2), ($cy + ($cell - $ic.Height)/2))
    $ic.Dispose()
}
$g.Dispose()
$out = Join-Path $root '_tmp_contact.png'
$sheet.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
$sheet.Dispose()
Write-Output ("contact sheet salva: " + $out + " (" + $files.Count + " icones)")
