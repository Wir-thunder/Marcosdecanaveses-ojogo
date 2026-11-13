Add-Type -AssemblyName System.Drawing

$art = "C:\Users\Icaro\.gemini\antigravity\brain\d230022c-e2cb-4685-b15f-9b28e390df89"
$bgDir = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Environment\backgrounds"
New-Item -ItemType Directory -Force -Path $bgDir | Out-Null

$stages = @(
    @{ Src = "stage1_castro_pedra_formosa.jpg";    Dst = "tongobriga_stage1_castro.png" },
    @{ Src = "stage2_termas_forum_tongobriga.jpg"; Dst = "tongobriga_stage2_termas.png" },
    @{ Src = "stage3_ponte_rio_tamega.jpg";        Dst = "tongobriga_stage3_ponte.png" },
    @{ Src = "stage4_praca_taverna_noite.jpg";     Dst = "tongobriga_stage4_praca_noite.png" }
)

foreach ($s in $stages) {
    $srcPath = Join-Path $art $s.Src
    $dstPath = Join-Path $bgDir $s.Dst
    $srcBmp = [System.Drawing.Bitmap]::new($srcPath)
    $outBmp = [System.Drawing.Bitmap]::new(640, 360, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($outBmp)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.DrawImage($srcBmp, [System.Drawing.Rectangle]::new(0, 0, 640, 360))
    $g.Dispose()
    $outBmp.Save($dstPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $srcBmp.Dispose()
    $outBmp.Dispose()
    Write-Output ("Installed 640x360 arena PNG: " + $dstPath)
}

