Add-Type -AssemblyName System.Drawing

function Get-BoundingBoxes($imagePath) {
    $bmp = [System.Drawing.Bitmap]::new($imagePath)
    $w = $bmp.Width
    $h = $bmp.Height
    Write-Output "Analyzing $imagePath ($w x $h)..."

    # Scan grid in blocks to find separate bounding boxes
    # Top half (Row 1) and Bottom half (Row 2)
    # Let's project horizontal and vertical darkness
    $colDark = New-Object int[] $w
    $rowDark = New-Object int[] $h

    for ($y = 0; $y -lt $h; $y += 2) {
        for ($x = 0; $x -lt $w; $x += 2) {
            $c = $bmp.GetPixel($x, $y)
            # if not pure white
            if ($c.R -lt 240 -or $c.G -lt 240 -or $c.B -lt 240) {
                $colDark[$x]++
                $rowDark[$y]++
            }
        }
    }

    # Find row split
    $midY = [int]($h / 2)
    Write-Output "Scanned."
    $bmp.Dispose()
}

Get-BoundingBoxes "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89\boar_forest_spritesheet_1793624127423.jpg"

