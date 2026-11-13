# Pós-processa um PNG gerado no Colab: remove fundo claro (flood fill a partir dos cantos),
# recorta ao conteúdo e reduz para o tamanho final com nearest-neighbor (pixel art nítida).
# Uso: .\ferramentas\pixelizar.ps1 -Entrada scratch\x.png -Saida Assets\...\x.png -Lado 64
param(
    [Parameter(Mandatory = $true)][string]$Entrada,
    [Parameter(Mandatory = $true)][string]$Saida,
    [int]$Lado = 64,
    [int]$Tolerancia = 38
)
Add-Type -AssemblyName System.Drawing

$src = [System.Drawing.Bitmap]::FromFile((Resolve-Path $Entrada))
$w = $src.Width; $h = $src.Height
$bmp = New-Object System.Drawing.Bitmap $w, $h, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($bmp); $g.DrawImage($src, 0, 0, $w, $h); $g.Dispose(); $src.Dispose()

# cor de fundo = média dos 4 cantos
$cantos = @($bmp.GetPixel(0, 0), $bmp.GetPixel($w - 1, 0), $bmp.GetPixel(0, $h - 1), $bmp.GetPixel($w - 1, $h - 1))
$br = ($cantos | ForEach-Object { $_.R } | Measure-Object -Average).Average
$bg = ($cantos | ForEach-Object { $_.G } | Measure-Object -Average).Average
$bb = ($cantos | ForEach-Object { $_.B } | Measure-Object -Average).Average

function Perto([System.Drawing.Color]$c) {
    return ([math]::Abs($c.R - $br) + [math]::Abs($c.G - $bg) + [math]::Abs($c.B - $bb)) -le $Tolerancia * 3 / 2
}

# flood fill iterativo a partir das bordas
$vis = New-Object 'bool[]' ($w * $h)
$fila = New-Object System.Collections.Generic.Queue[int]
for ($x = 0; $x -lt $w; $x++) { $fila.Enqueue($x); $fila.Enqueue(($h - 1) * $w + $x) }
for ($y = 0; $y -lt $h; $y++) { $fila.Enqueue($y * $w); $fila.Enqueue($y * $w + $w - 1) }
$transp = [System.Drawing.Color]::FromArgb(0, 0, 0, 0)
while ($fila.Count -gt 0) {
    $i = $fila.Dequeue()
    if ($vis[$i]) { continue }
    $x = $i % $w; $y = [math]::Floor($i / $w)
    if (-not (Perto $bmp.GetPixel($x, $y))) { continue }
    $vis[$i] = $true
    $bmp.SetPixel($x, $y, $transp)
    if ($x -gt 0) { $fila.Enqueue($i - 1) }
    if ($x -lt $w - 1) { $fila.Enqueue($i + 1) }
    if ($y -gt 0) { $fila.Enqueue($i - $w) }
    if ($y -lt $h - 1) { $fila.Enqueue($i + $w) }
}

# bounding box do conteúdo opaco
$minX = $w; $minY = $h; $maxX = 0; $maxY = 0
for ($y = 0; $y -lt $h; $y++) { for ($x = 0; $x -lt $w; $x++) {
    if ($bmp.GetPixel($x, $y).A -gt 0) {
        if ($x -lt $minX) { $minX = $x }; if ($x -gt $maxX) { $maxX = $x }
        if ($y -lt $minY) { $minY = $y }; if ($y -gt $maxY) { $maxY = $y }
    } } }
$cw = $maxX - $minX + 1; $ch = $maxY - $minY + 1
$lado_max = [math]::Max($cw, $ch)
$escala = $Lado / $lado_max
$nw = [math]::Max(1, [int][math]::Round($cw * $escala)); $nh = [math]::Max(1, [int][math]::Round($ch * $escala))

$out = New-Object System.Drawing.Bitmap $Lado, $Lado, ([System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$go = [System.Drawing.Graphics]::FromImage($out)
$go.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
$go.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
$destX = [int](($Lado - $nw) / 2); $destY = $Lado - $nh   # encosta ao fundo (pés/base)
$go.DrawImage($bmp, (New-Object System.Drawing.Rectangle $destX, $destY, $nw, $nh),
    (New-Object System.Drawing.Rectangle $minX, $minY, $cw, $ch), [System.Drawing.GraphicsUnit]::Pixel)
$go.Dispose()

$dir = Split-Path -Parent $Saida
if ($dir -and -not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
$out.Save((Join-Path (Get-Location) $Saida), [System.Drawing.Imaging.ImageFormat]::Png)
$bmp.Dispose(); $out.Dispose()
Write-Output "OK $Saida ($nw x $nh dentro de $Lado x $Lado)"
