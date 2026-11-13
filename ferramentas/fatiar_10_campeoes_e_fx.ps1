Add-Type -AssemblyName System.Drawing
$ErrorActionPreference = "Stop"

$artDir = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89"
$rawDir = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Source\raw\tongobriga_roster_v2"
$outCharsDir = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Characters\Tongobriga"

$CanvasW = 192
$CanvasH = 140
$FootY   = 134 # Matches AnimatedSprite2D centered=true + offset=(0, -64) -> local y = 0!

$roster = @(
    @{ Id = "warrior";   Sheet = "01_viriato_spritesheet.jpg";    Concept = (Join-Path $artDir "viriato_character_sheet_1793717351948.jpg");       IdleH = 114; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "archer";    Sheet = "02_nabia_spritesheet.jpg";      Concept = (Join-Path $artDir "nabia_fighting_game_showcase_1793717348686.jpg");  IdleH = 110; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "mage";      Sheet = "03_endovelico_spritesheet.jpg"; Concept = (Join-Path $artDir "endovelico_arcade_showcase_1793717371591.jpg");    IdleH = 118; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "healer";    Sheet = "04_aunia_spritesheet.jpg";      Concept = (Join-Path $artDir "aunia_character_concept_sheet_1793717353626.jpg"); IdleH = 112; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "breno";     Sheet = "05_breno_spritesheet.jpg";      Concept = (Join-Path $artDir "breno_nano_banana_v1.jpg");                        IdleH = 116; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "bracaro";   Sheet = "06_bracaro_spritesheet.jpg";    Concept = (Join-Path $artDir "bracaro_celtic_helmet_showcase_1793719756583.jpg"); IdleH = 122; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "decimo";    Sheet = "07_decimo_spritesheet.jpg";     Concept = (Join-Path $artDir "decimo_bruto_character_sheet_1793717359748.jpg");  IdleH = 118; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "trebaruna"; Sheet = "08_trebaruna_spritesheet.jpg";  Concept = (Join-Path $artDir "trebaruna_character_showcase_1793717416579.jpg");  IdleH = 110; PortRect = @(0.025, 0.04, 0.36, 0.64) },
    @{ Id = "klaudia";   Sheet = "09_klaudia_spritesheet.jpg";    Concept = (Join-Path $artDir "klaudia_slavic_folk_v2.jpg");                      IdleH = 110; PortRect = @(0.020, 0.03, 0.37, 0.66) },
    @{ Id = "marco";     Sheet = "10_marco_spritesheet.jpg";      Concept = (Join-Path $artDir "marco_ingame_faithful_v2.jpg");                    IdleH = 112; PortRect = @(0.025, 0.04, 0.36, 0.64) }
)

function Find-MinColumn([byte[]]$mask, [int]$W, [int]$y0, [int]$y1, [int]$xMin, [int]$xMax) {
    $bestX = [int](($xMin + $xMax) / 2)
    $bestScore = 99999999
    $mid = ($xMin + $xMax) * 0.5
    for ($x = $xMin; $x -le $xMax; $x++) {
        $cnt = 0
        for ($y = $y0; $y -lt $y1; $y++) {
            if ($mask[$y * $W + $x] -eq 1) { $cnt++ }
        }
        $score = $cnt * 1000 + [int]([Math]::Abs($x - $mid))
        if ($score -lt $bestScore) {
            $bestScore = $score
            $bestX = $x
        }
    }
    return $bestX
}

function Analyze-Cell([byte[]]$mask, [int]$W, [int]$x0, [int]$y0, [int]$x1, [int]$y1) {
    $minX = $x1; $maxX = -1; $minY = $y1; $maxY = -1
    for ($y = $y0; $y -lt $y1; $y++) {
        $mOff = $y * $W
        for ($x = $x0; $x -lt $x1; $x++) {
            if ($mask[$mOff + $x] -eq 1) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    if ($maxX -lt $minX) {
        return @{ Valid = $false; X = 0; Y = 0; W = 1; H = 1; CoreRatioX = 0.5 }
    }
    $bw = $maxX - $minX + 1
    $bh = $maxY - $minY + 1
    $legStart = $minY + [int]($bh * 0.52)
    $sumX = 0.0; $cntCore = 0
    for ($y = $legStart; $y -le $maxY; $y++) {
        $mOff = $y * $W
        for ($x = $minX; $x -le $maxX; $x++) {
            if ($mask[$mOff + $x] -eq 1) {
                $sumX += ($x - $minX)
                $cntCore++
            }
        }
    }
    $coreRatio = if ($cntCore -gt 20) { ($sumX / $cntCore) / [double]$bw } else { 0.5 }
    return @{ Valid = $true; X = $minX; Y = $minY; W = $bw; H = $bh; CoreRatioX = $coreRatio }
}

foreach ($ch in $roster) {
    $id = $ch.Id
    $charDir = Join-Path $outCharsDir $id
    New-Item -ItemType Directory -Force -Path $charDir | Out-Null
    Get-ChildItem -Path $charDir -Filter "*.png" -ErrorAction SilentlyContinue | Remove-Item -Force

    # 1. Export crisp 128x128 portrait.png
    $conceptBmp = [System.Drawing.Bitmap]::new($ch.Concept)
    $cw = $conceptBmp.Width; $chh = $conceptBmp.Height
    $pr = $ch.PortRect
    $px = [int]($cw * $pr[0]); $py = [int]($chh * $pr[1])
    $pw = [int]($cw * $pr[2])
    $portBmp = [System.Drawing.Bitmap]::new(128, 128, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gp = [System.Drawing.Graphics]::FromImage($portBmp)
    $gp.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gp.DrawImage($conceptBmp, [System.Drawing.Rectangle]::new(0, 0, 128, 128), [System.Drawing.Rectangle]::new($px, $py, $pw, [Math]::Min($chh - $py, [int]($pw * 1.05))), [System.Drawing.GraphicsUnit]::Pixel)
    $gp.Dispose()
    $portBmp.Save((Join-Path $charDir "portrait.png"), [System.Drawing.Imaging.ImageFormat]::Png)
    $portBmp.Dispose()
    $conceptBmp.Dispose()

    # 2. Load 2x4 spritesheet & chroma-key with LockBits + despill
    $sheetPath = Join-Path $rawDir $ch.Sheet
    $rawBmp = [System.Drawing.Bitmap]::new($sheetPath)
    $W = $rawBmp.Width; $H = $rawBmp.Height
    $rgba = [System.Drawing.Bitmap]::new($W, $H, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gCopy = [System.Drawing.Graphics]::FromImage($rgba)
    $gCopy.DrawImage($rawBmp, 0, 0, $W, $H)
    $gCopy.Dispose()
    $rawBmp.Dispose()

    $bgSample = $rgba.GetPixel(6, 6)
    $isGreenKey = ($bgSample.G -gt ($bgSample.R + 70) -and $bgSample.G -gt ($bgSample.B + 70))

    $rect = [System.Drawing.Rectangle]::new(0, 0, $W, $H)
    $lock = $rgba.LockBits($rect, [System.Drawing.Imaging.ImageLockMode]::ReadWrite, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $stride = $lock.Stride
    $bytes = [byte[]]::new($stride * $H)
    [System.Runtime.InteropServices.Marshal]::Copy($lock.Scan0, $bytes, 0, $bytes.Length)

    $mask = [byte[]]::new($W * $H)
    for ($y = 0; $y -lt $H; $y++) {
        $rowOff = $y * $stride
        $mOff = $y * $W
        for ($x = 0; $x -lt $W; $x++) {
            $o = $rowOff + $x * 4
            $b = [int]$bytes[$o]; $g = [int]$bytes[$o + 1]; $r = [int]$bytes[$o + 2]
            $isBg = $false
            if ($isGreenKey) {
                $excessG = $g - [Math]::Max($r, $b)
                if ($excessG -gt 52 -and $g -gt 135) {
                    $isBg = $true
                } elseif ($excessG -gt 24 -and $g -gt 110) {
                    $bytes[$o + 1] = [byte]([Math]::Min(255, [Math]::Max($r, $b) + 6))
                }
            } else {
                $minRB = [Math]::Min($r, $b)
                $excessM = $minRB - $g
                if ($excessM -gt 58 -and $r -gt 145 -and $b -gt 145) {
                    $isBg = $true
                } elseif ($excessM -gt 28 -and $r -gt 120 -and $b -gt 120) {
                    $clampRB = [byte]([Math]::Min(255, $g + 18))
                    $bytes[$o] = [Math]::Min($bytes[$o], $clampRB)
                    $bytes[$o + 2] = [Math]::Min($bytes[$o + 2], $clampRB)
                }
            }
            if ($isBg) {
                $bytes[$o] = 0; $bytes[$o + 1] = 0; $bytes[$o + 2] = 0; $bytes[$o + 3] = 0
            } else {
                $bytes[$o + 3] = 255
                $mask[$mOff + $x] = 1
            }
        }
    }

    for ($y = 1; $y -lt ($H - 1); $y++) {
        $mOff = $y * $W
        $rowOff = $y * $stride
        for ($x = 1; $x -lt ($W - 1); $x++) {
            if ($mask[$mOff + $x] -eq 1) {
                $nb = $mask[$mOff + $x - 1] + $mask[$mOff + $x + 1] + $mask[$mOff - $W + $x] + $mask[$mOff + $W + $x]
                if ($nb -eq 0) {
                    $mask[$mOff + $x] = 0
                    $bytes[$rowOff + $x * 4 + 3] = 0
                }
            }
        }
    }

    [System.Runtime.InteropServices.Marshal]::Copy($bytes, 0, $lock.Scan0, $bytes.Length)
    $rgba.UnlockBits($lock)

    # 3. Split Row 0 / Row 1 and 4 columns per row cleanly
    $bestSplitY = [int]($H * 0.49)
    $minRowCnt = 999999
    for ($y = [int]($H * 0.42); $y -le [int]($H * 0.56); $y++) {
        $cnt = 0; $mOff = $y * $W
        for ($x = 0; $x -lt $W; $x++) { if ($mask[$mOff + $x] -eq 1) { $cnt++ } }
        if ($cnt -lt $minRowCnt) { $minRowCnt = $cnt; $bestSplitY = $y }
    }

    $t1 = Find-MinColumn $mask $W 0 $bestSplitY ([int]($W * 0.18)) ([int]($W * 0.32))
    $t2 = Find-MinColumn $mask $W 0 $bestSplitY ([int]($W * 0.42)) ([int]($W * 0.58))
    $t3 = Find-MinColumn $mask $W 0 $bestSplitY ([int]($W * 0.68)) ([int]($W * 0.82))

    $b1 = Find-MinColumn $mask $W $bestSplitY $H ([int]($W * 0.18)) ([int]($W * 0.32))
    $b2 = Find-MinColumn $mask $W $bestSplitY $H ([int]($W * 0.42)) ([int]($W * 0.58))
    $b3 = Find-MinColumn $mask $W $bestSplitY $H ([int]($W * 0.68)) ([int]($W * 0.82))

    $bboxes = @(
        (Analyze-Cell $mask $W 0   0           $t1 $bestSplitY), # 0: Idle
        (Analyze-Cell $mask $W $t1 0           $t2 $bestSplitY), # 1: Move
        (Analyze-Cell $mask $W $t2 0           $t3 $bestSplitY), # 2: Block
        (Analyze-Cell $mask $W $t3 0           $W  $bestSplitY), # 3: Jump
        (Analyze-Cell $mask $W 0   $bestSplitY $b1 $H),          # 4: Punch
        (Analyze-Cell $mask $W $b1 $bestSplitY $b2 $H),          # 5: Kick
        (Analyze-Cell $mask $W $b2 $bestSplitY $b3 $H),          # 6: Special
        (Analyze-Cell $mask $W $b3 $bestSplitY $W  $H)           # 7: Damage / Defeated
    )

    $srcIdleH = [Math]::Max(80, [int]$bboxes[0].H)
    $charScale = $ch.IdleH / [double]$srcIdleH

    function Write-Frame([int]$cellIdx, [string]$fileName, [int]$footOff = 0, [int]$dx = 0, [double]$sqY = 1.0) {
        $bb = $bboxes[$cellIdx]
        $canvas = [System.Drawing.Bitmap]::new($CanvasW, $CanvasH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        if ($bb.Valid) {
            $dstW = [Math]::Max(1, [int]([Math]::Round($bb.W * $charScale)))
            $dstH = [Math]::Max(1, [int]([Math]::Round($bb.H * $charScale * $sqY)))
            if ($dstH -gt ($FootY - 2)) {
                $fit = ($FootY - 2) / [double]$dstH
                $dstH = [int]([Math]::Round($dstH * $fit))
                $dstW = [int]([Math]::Round($dstW * $fit))
            }
            if ($dstW -gt ($CanvasW - 4)) {
                $fitW = ($CanvasW - 4) / [double]$dstW
                $dstW = [int]([Math]::Round($dstW * $fitW))
                $dstH = [int]([Math]::Round($dstH * $fitW))
            }
            $scaledCoreX = $bb.CoreRatioX * $dstW
            $drawX = [int]([Math]::Round(($CanvasW * 0.48) - $scaledCoreX + $dx))
            if ($drawX -lt 2) { $drawX = 2 }
            if ($drawX + $dstW -gt ($CanvasW - 2)) { $drawX = $CanvasW - 2 - $dstW }
            $drawY = $FootY + $footOff - $dstH
            if ($drawY -lt 1) { $drawY = 1 }

            $g = [System.Drawing.Graphics]::FromImage($canvas)
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
            $g.DrawImage(
                $rgba,
                [System.Drawing.Rectangle]::new($drawX, $drawY, $dstW, $dstH),
                [System.Drawing.Rectangle]::new($bb.X, $bb.Y, $bb.W, $bb.H),
                [System.Drawing.GraphicsUnit]::Pixel
            )
            $g.Dispose()
        }
        $canvas.Save((Join-Path $charDir $fileName), [System.Drawing.Imaging.ImageFormat]::Png)
        $canvas.Dispose()
    }

    Write-Frame 0 "idle_1.png" 0 0 1.00
    Write-Frame 0 "idle_2.png" 0 0 1.00
    Write-Frame 0 "idle_3.png" 1 0 1.00
    Write-Frame 0 "idle_4.png" 0 0 1.00

    Write-Frame 0 "move_1.png" 0 0 1.00
    Write-Frame 1 "move_2.png" -1 2 1.00
    Write-Frame 1 "move_3.png" 0 3 1.00
    Write-Frame 0 "move_4.png" -1 1 1.00

    Write-Frame 3 "jump_1.png" -8 0 1.00
    Write-Frame 3 "jump_2.png" -10 2 1.00

    Write-Frame 0 "punch_1.png" 0 3 1.00
    Write-Frame 4 "punch_2.png" 0 6 1.00
    Write-Frame 4 "punch_3.png" 0 4 1.00

    Write-Frame 1 "kick_1.png" 0 2 1.00
    Write-Frame 5 "kick_2.png" 0 5 1.00
    Write-Frame 5 "kick_3.png" 0 3 1.00

    Write-Frame 2 "special_1.png" 0 -1 1.00
    Write-Frame 6 "special_2.png" 0 5 1.00
    Write-Frame 6 "special_3.png" 0 6 1.00

    Write-Frame 2 "block_1.png" 0 0 1.00
    Write-Frame 2 "block_2.png" 0 -1 1.00

    Write-Frame 7 "damage_1.png" 0 -3 1.00
    Write-Frame 7 "damage_2.png" 0 -5 1.00

    Write-Frame 7 "defeated_1.png" 0 -4 1.00
    Write-Frame 7 "defeated_2.png" 2 -6 1.00

    $rgba.Dispose()
    Write-Output ("[$id] Sliced 23 frames + 128x128 portrait (srcIdleH=$srcIdleH, scale=$([Math]::Round($charScale, 3)))")
}

Write-Output "ALL 10 CHAMPIONS SLICED IN ULTRA-FAST MODE!"
