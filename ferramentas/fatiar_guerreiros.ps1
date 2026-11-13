<#
  fatiar_guerreiros.ps1
  Fatiar a spritesheet "Guerreiros de tongobriga.jpeg" em PNGs transparentes,
  organizados por classe e estado de animacao.

  Metodo: deteta o numero de frames e o passo (pitch) a partir do estado IDLE
  de cada classe, e depois fatia TODOS os estados por grade regular centrada
  nos frames do idle. Assim os ataques (em que bracos/armas ligam sprites)
  ficam correctamente separados. Cada frame sai num canvas normalizado
  (bottom-aligned, centrado) para nao tremer na animacao do Godot.

  Uso:
    powershell -ExecutionPolicy Bypass -File ferramentas\fatiar_guerreiros.ps1
    powershell -ExecutionPolicy Bypass -File ferramentas\fatiar_guerreiros.ps1 -DryRun
#>
param(
    [string]$Src = "Sprites\Guerreiros de tongobriga.jpeg",
    [string]$Out = "Assets\Sprites\Tongobriga",
    [int]$CanvasW = 210,
    [int]$CanvasH = 170,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

# Faixas X por classe (na imagem original 2752x1536)
$classes = @(
    @{ Nome = "warrior"; X0 = 222; X1 = 687 },
    @{ Nome = "archer";  X0 = 854; X1 = 1333 },
    @{ Nome = "mage";    X0 = 1479; X1 = 2030 },
    @{ Nome = "healer";  X0 = 2168; X1 = 2687 }
)

# Faixas Y por estado
$estados = @(
    @{ Nome = "idle";     Y0 = 148; Y1 = 282 },
    @{ Nome = "move";     Y0 = 308; Y1 = 442 },
    @{ Nome = "jump";     Y0 = 482; Y1 = 616 },
    @{ Nome = "punch";    Y0 = 630; Y1 = 758 },
    @{ Nome = "kick";     Y0 = 778; Y1 = 907 },
    @{ Nome = "special";  Y0 = 936; Y1 = 1064 },
    @{ Nome = "block";    Y0 = 1080; Y1 = 1210 },
    @{ Nome = "damage";   Y0 = 1236; Y1 = 1362 },
    @{ Nome = "defeated"; Y0 = 1408; Y1 = 1500 }
)

$srcPath = (Resolve-Path $Src).Path
$img = [System.Drawing.Image]::FromFile($srcPath)
$bmp = New-Object System.Drawing.Bitmap($img)
$W = $bmp.Width; $H = $bmp.Height
$rect = New-Object System.Drawing.Rectangle(0, 0, $W, $H)
$lock = $bmp.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadOnly, $bmp.PixelFormat)
$stride = $lock.Stride
$nbytes = $stride * $H
$arr = [byte[]]::new($nbytes)
[System.Runtime.InteropServices.Marshal]::Copy($lock.Scan0, $arr, 0, $nbytes)
$bpp = $stride / $W

Write-Output ("Origem: " + $srcPath + "  (" + $W + "x" + $H + ")")
if ($DryRun) { Write-Output "*** DRY-RUN: nada sera gravado ***" }
Write-Output ("Destino: " + (Join-Path (Get-Location) $Out))
Write-Output "A pre-calcular mascara de conteudo..."

# Mascara 1D: 1 = sprite, 0 = fundo checkerboard.
$mask = [byte[]]::new($W * $H)
for ($y = 0; $y -lt $H; $y++) {
    $rowBase = $y * $stride
    $mBase = $y * $W
    for ($x = 0; $x -lt $W; $x++) {
        $o = $rowBase + [int]($x * $bpp)
        $r = $arr[$o + 2]; $g = $arr[$o + 1]; $b = $arr[$o]
        $mx = $r; if ($g -gt $mx) { $mx = $g }; if ($b -gt $mx) { $mx = $b }
        $mn = $r; if ($g -lt $mn) { $mn = $g }; if ($b -lt $mn) { $mn = $b }
        $sat = $mx - $mn
        if ($sat -ge 28 -or $mn -lt 82 -or $mx -gt 198) { $mask[$mBase + $x] = 1 }
    }
}
Write-Output "Mascara pronta."

$total = 0
$porClasse = @{}

foreach ($cl in $classes) {
    $dir = Join-Path $Out $cl.Nome
    if (-not $DryRun) {
        if (Test-Path $dir) { Remove-Item ($dir + '\*.*') -Force -ErrorAction SilentlyContinue }
        New-Item -ItemType Directory -Force -Path $dir | Out-Null
    }
    $count = 0
    Write-Output ("=== " + $cl.Nome.ToUpper() + " ===")

    # 1) Deteta centros dos frames a partir do IDLE desta classe (inline,
    # por projeccao de conteudo: agrupa colunas com conteudo separadas por gaps).
    $idleRow = ($estados | Where-Object { $_.Nome -eq "idle" })[0]
    $iy0 = $idleRow.Y0; $iy1 = $idleRow.Y1
    $centrosList = New-Object System.Collections.ArrayList
    $s = -1; $gap = 0
    for ($x = $cl.X0; $x -le $cl.X1; $x++) {
        $c = 0; $mb = $iy0 * $W + $x
        for ($y = $iy0; $y -le $iy1; $y++) { if ($mask[$mb] -eq 1) { $c++ }; $mb += $W }
        if ($c -gt 1) { if ($s -lt 0) { $s = $x }; $gap = 0 }
        elseif ($s -ge 0) {
            $gap++
            if ($gap -ge 6) { [void]$centrosList.Add([int](($s + ($x - $gap)) / 2)); $s = -1; $gap = 0 }
        }
    }
    if ($s -ge 0) { [void]$centrosList.Add([int](($s + $cl.X1) / 2)) }
    $centros = @($centrosList)
    $nf = $centros.Count
    if ($nf -lt 2) { Write-Output ("  (idle deu " + $nf + " frames, a saltar)"); continue }

    # pitch medio (centro a centro)
    $pitchSum = 0
    for ($i = 1; $i -lt $nf; $i++) { $pitchSum += ($centros[$i] - $centros[$i - 1]) }
    $pitch = [int]($pitchSum / ($nf - 1))
    # meia-largura de cada fatia (com folga para armas esticadas)
    $half = [int]($pitch * 0.62)
    Write-Output ("  idle: " + $nf + " frames, pitch=" + $pitch + ", meia-fatia=" + $half)

    # 2) Fatiar cada estado em nf fatias centradas nos centros do idle.
    foreach ($est in $estados) {
        $y0 = $est.Y0; $y1 = $est.Y1
        for ($k = 0; $k -lt $nf; $k++) {
            $cx = $centros[$k]
            $fx0 = $cx - $half; $fx1 = $cx + $half
            if ($fx0 -lt $cl.X0) { $fx0 = $cl.X0 }
            if ($fx1 -gt $cl.X1) { $fx1 = $cl.X1 }

            # bounding box do conteudo (autocrop) dentro da fatia
            $fw = $fx1 - $fx0 + 1; $fh = $y1 - $y0 + 1
            $bx0 = $fw; $by0 = $fh; $bx1 = -1; $by1 = -1
            for ($yy = 0; $yy -lt $fh; $yy++) {
                $mBase = ($y0 + $yy) * $W + $fx0
                for ($xx = 0; $xx -lt $fw; $xx++) {
                    if ($mask[$mBase + $xx] -eq 1) {
                        if ($xx -lt $bx0) { $bx0 = $xx }
                        if ($xx -gt $bx1) { $bx1 = $xx }
                        if ($yy -lt $by0) { $by0 = $yy }
                        if ($yy -gt $by1) { $by1 = $yy }
                    }
                }
            }
            if ($bx1 -lt 0) { continue }
            $cw = $bx1 - $bx0 + 1; $chh = $by1 - $by0 + 1
            if ($cw -le 0 -or $chh -le 0) { continue }
            if ($cw -gt $CanvasW) { $cw = $CanvasW }
            if ($chh -gt $CanvasH) { $chh = $CanvasH }
            $name = ("{0}_{1}.png" -f $est.Nome, ($k + 1))

            if ($DryRun) {
                Write-Output ("  {0,-10} -> {1,-13} cx={2,-4} crop {3}x{4}" -f $est.Nome, $name, $cx, $cw, $chh)
            } else {
                $ox = [int](($CanvasW - $cw) / 2)
                $oy = $CanvasH - $chh
                $outBmp = New-Object System.Drawing.Bitmap($CanvasW, $CanvasH)
                $orect = New-Object System.Drawing.Rectangle(0, 0, $CanvasW, $CanvasH)
                $olock = $outBmp.LockBits($orect, [System.Drawing.Imaging.ImageLockMode]::WriteOnly, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
                $ostride = $olock.Stride
                $oarr = [byte[]]::new($ostride * $CanvasH)
                for ($yy = 0; $yy -lt $chh; $yy++) {
                    $sx = $fx0 + $bx0
                    $sy = $y0 + $by0 + $yy
                    $rowBase = $sy * $stride
                    $mBase = $sy * $W + $sx
                    $oo = ($oy + $yy) * $ostride + $ox * 4
                    for ($xx = 0; $xx -lt $cw; $xx++) {
                        $o = $rowBase + [int]($sx * $bpp)
                        $oarr[$oo] = $arr[$o]; $oarr[$oo + 1] = $arr[$o + 1]; $oarr[$oo + 2] = $arr[$o + 2]
                        $oarr[$oo + 3] = 0
                        if ($mask[$mBase] -eq 1) { $oarr[$oo + 3] = 255 }
                        $sx++; $mBase++; $oo += 4
                    }
                }
                [System.Runtime.InteropServices.Marshal]::Copy($oarr, 0, $olock.Scan0, $oarr.Length)
                $outBmp.UnlockBits($olock)
                $outBmp.Save((Join-Path $dir $name), [System.Drawing.Imaging.ImageFormat]::Png)
                $outBmp.Dispose()
            }
            $count++; $total++
        }
    }
    $porClasse[$cl.Nome] = $count
    Write-Output ("  -> " + $count + " frames`n")
}

$bmp.UnlockBits($lock); $bmp.Dispose(); $img.Dispose()
Write-Output ("TOTAL: " + $total + " sprites  (canvas " + $CanvasW + "x" + $CanvasH + ")")
foreach ($k in $porClasse.Keys) { Write-Output ("  " + $k + ": " + $porClasse[$k]) }

