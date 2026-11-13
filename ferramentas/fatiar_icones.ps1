# fatiar_icones.ps1
# Fatia Sprites/Imagens_pocoes_ingredientes.jpeg em icones PNG (fundo transparente)
# e guarda em Assets/Icons/Ingredients e Assets/Icons/Potions com o nome do id.
#
# Uso (na raiz do projeto):
#     powershell -ExecutionPolicy Bypass -File ferramentas\fatiar_icones.ps1
#     powershell -ExecutionPolicy Bypass -File ferramentas\fatiar_icones.ps1 -DryRun

param(
    [switch]$DryRun
)

Add-Type -AssemblyName System.Drawing

$root   = Split-Path -Parent $PSScriptRoot
$src    = (Resolve-Path (Join-Path $root 'Sprites\Imagens_pocoes_ingredientes.jpeg')).Path
$outIng = (Resolve-Path (Join-Path $root 'Assets\Icons\Ingredients')).Path
$outPot = (Resolve-Path (Join-Path $root 'Assets\Icons\Potions')).Path

# (nome/id, x0, x1, y0, y1, destino)  -- coordenadas 0-based inclusivas
$sprites = @(
    # Linha 1 (y 56-362): 5 ingredientes
    @{ n='hortela_nobre';        x0=77;   x1=377;  y0=56;  y1=362;  d='ing' }
    @{ n='musgo_aboboreira';     x0=588;  x1=893;  y0=56;  y1=362;  d='ing' }
    @{ n='arnica_selvagem';      x0=1092; x1=1379; y0=56;  y1=362;  d='ing' }
    @{ n='calcedonia_fina';      x0=1511; x1=1835; y0=56;  y1=362;  d='ing' }
    @{ n='erva_cidreira_fina';   x0=1968; x1=2291; y0=56;  y1=362;  d='ing' }
    # Linha 2 (y 614-931): 3 ingredientes
    @{ n='erva_cidreira';        x0=139;  x1=467;  y0=614; y1=931;  d='ing' }
    @{ n='po_granito_tongobriga';x0=690;  x1=1090; y0=614; y1=931;  d='ing' }
    @{ n='azeite_do_olival';     x0=1403; x1=1661; y0=614; y1=931;  d='ing' }
    # Linha 3 (y 1236-1652): 4 pocoes
    @{ n='pocao_vento_ligeiro';  x0=168;  x1=479;  y0=1236;y1=1652; d='pot' }
    @{ n='pocao_espinheira_real';x0=732;  x1=1079; y0=1236;y1=1652; d='pot' }
    @{ n='pocao_mente_limpida';  x0=1362; x1=1643; y0=1236;y1=1652; d='pot' }
    @{ n='pocao_escudo_do_lago'; x0=1961; x1=2231; y0=1236;y1=1652; d='pot' }
)

# cor de fundo aproximada (RGB lido da imagem)
$bgR = 129; $bgG = 122; $bgB = 114
$TIN  = 14    # <= esta distancia do fundo => totalmente transparente
$TOUT = 48    # >= esta distancia => totalmente opaco (aresta do sprite)
$CANVAS = 128 # saida quadrada
$PAD    = 3    # margem apos o crop ao conteudo

$img = [System.Drawing.Image]::FromFile($src)
$criados = @()
foreach ($s in $sprites) {
    $w = $s.x1 - $s.x0 + 1
    $h = $s.y1 - $s.y0 + 1
    $fmt = [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    $crop = New-Object System.Drawing.Bitmap($w, $h, $fmt)
    $g0 = [System.Drawing.Graphics]::FromImage($crop)
    $g0.DrawImage($img, (New-Object System.Drawing.Rectangle(0,0,$w,$h)), (New-Object System.Drawing.Rectangle($s.x0,$s.y0,$w,$h)), [System.Drawing.GraphicsUnit]::Pixel)
    $g0.Dispose()

    $rect  = New-Object System.Drawing.Rectangle(0,0,$w,$h)
    $lock  = $crop.LockBits($rect, 'ReadWrite', $fmt)
    $stride = $lock.Stride
    $data  = New-Object byte[] ($stride*$h)
    [System.Runtime.InteropServices.Marshal]::Copy($lock.Scan0, $data, 0, $data.Length)

    $n = $w*$h
    $md     = New-Object 'int[]'  $n
    $alpha  = New-Object 'int[]'  $n
    $visited= New-Object 'bool[]' $n
    for ($i=0; $i -lt $n; $i++) {
        $o = $i*4
        $dr = [math]::Abs($data[$o+2] - $bgR)
        $dg = [math]::Abs($data[$o+1] - $bgG)
        $db = [math]::Abs($data[$o]   - $bgB)
        $m = $dr; if ($dg -gt $m) { $m = $dg }; if ($db -gt $m) { $m = $db }
        $md[$i] = $m
        $alpha[$i] = 255
    }

    # flood-fill do fundo a partir das 4 bordas
    $stack = New-Object System.Collections.Stack
    for ($x=0; $x -lt $w; $x++) {
        foreach ($yy in @(0, ($h-1))) { $idx = $yy*$w + $x; if (-not $visited[$idx] -and $md[$idx] -le $TOUT) { $visited[$idx]=$true; $stack.Push($idx) } }
    }
    for ($y=0; $y -lt $h; $y++) {
        foreach ($xx in @(0, ($w-1))) { $idx = $y*$w + $xx; if (-not $visited[$idx] -and $md[$idx] -le $TOUT) { $visited[$idx]=$true; $stack.Push($idx) } }
    }
    while ($stack.Count -gt 0) {
        $idx = $stack.Pop()
        $m = $md[$idx]
        if ($m -le $TIN) { $alpha[$idx] = 0 } elseif ($m -ge $TOUT) { $alpha[$idx] = 255 } else { $alpha[$idx] = [int]((($m - $TIN) / ($TOUT - $TIN)) * 255) }
        $x = $idx % $w; $y = [math]::Floor($idx / $w)
        if ($x+1 -lt $w) { $j=$idx+1; if (-not $visited[$j] -and $md[$j] -le $TOUT) { $visited[$j]=$true; $stack.Push($j) } }
        if ($x-1 -ge 0)   { $j=$idx-1; if (-not $visited[$j] -and $md[$j] -le $TOUT) { $visited[$j]=$true; $stack.Push($j) } }
        if ($y+1 -lt $h)  { $j=$idx+$w; if (-not $visited[$j] -and $md[$j] -le $TOUT) { $visited[$j]=$true; $stack.Push($j) } }
        if ($y-1 -ge 0)   { $j=$idx-$w; if (-not $visited[$j] -and $md[$j] -le $TOUT) { $visited[$j]=$true; $stack.Push($j) } }
    }
    for ($i=0; $i -lt $n; $i++) { $data[$i*4+3] = [byte]$alpha[$i] }
    [System.Runtime.InteropServices.Marshal]::Copy($data, 0, $lock.Scan0, $data.Length)
    $crop.UnlockBits($lock)

    # crop ao conteudo util (alpha > 12)
    $minX=$w; $minY=$h; $maxX=-1; $maxY=-1
    for ($y=0; $y -lt $h; $y++) {
        for ($x=0; $x -lt $w; $x++) {
            if ($alpha[$y*$w+$x] -gt 12) {
                if ($x -lt $minX) { $minX=$x }; if ($x -gt $maxX) { $maxX=$x }
                if ($y -lt $minY) { $minY=$y }; if ($y -gt $maxY) { $maxY=$y }
            }
        }
    }
    if ($maxX -lt 0) { Write-Output ("[!] sem conteudo: " + $s.n); $crop.Dispose(); continue }

    $minX = [math]::Max(0, $minX - $PAD); $minY = [math]::Max(0, $minY - $PAD)
    $maxX = [math]::Min($w-1, $maxX + $PAD); $maxY = [math]::Min($h-1, $maxY + $PAD)
    $tw = $maxX - $minX + 1; $th = $maxY - $minY + 1
    $trim = $crop.Clone((New-Object System.Drawing.Rectangle($minX,$minY,$tw,$th)), $fmt)
    $crop.Dispose()

    # encaixa no quadrado CANVAS mantendo proporcao, centrado
    $scale = [math]::Min([double]$CANVAS / $tw, [double]$CANVAS / $th)
    $dw = [math]::Max(1, [int]($tw * $scale))
    $dh = [math]::Max(1, [int]($th * $scale))
    $final = New-Object System.Drawing.Bitmap($CANVAS, $CANVAS, $fmt)
    $g = [System.Drawing.Graphics]::FromImage($final)
    $g.Clear([System.Drawing.Color]::FromArgb(0,0,0,0))
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode  = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.SmoothingMode    = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.DrawImage($trim, [int](($CANVAS-$dw)/2), [int](($CANVAS-$dh)/2), $dw, $dh)
    $g.Dispose()
    $trim.Dispose()

    $destDir = if ($s.d -eq 'pot') { $outPot } else { $outIng }
    $out = Join-Path $destDir ($s.n + '.png')

    if ($DryRun) {
        Write-Output ("[dry-run] " + $s.n + ".png  (" + $dw + "x" + $dh + ")")
    } else {
        $final.Save($out, [System.Drawing.Imaging.ImageFormat]::Png)
        Write-Output ("[ok] " + $out)
        $criados += $s.n
    }
    $final.Dispose()
}

$img.Dispose()
Write-Output ('-' * 52)
if ($DryRun) { Write-Output 'Dry-run: nenhum ficheiro escrito.' }
else { Write-Output ('Icones criados: ' + $criados.Count) }

