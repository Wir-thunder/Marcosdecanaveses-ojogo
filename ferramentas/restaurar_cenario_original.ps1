Add-Type -AssemblyName System.Drawing

$src = Get-Item "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Sprites\Cen*rio_loja.jpeg"
$dst = "c:\Users\Icaro\Documents\marcos-de-canaveses--jogo\Assets\Environment\backgrounds\loja_cenario.png"

Write-Host "Source found: $($src.FullName)"
$bmp = [System.Drawing.Bitmap]::FromFile($src.FullName)

$resized = New-Object System.Drawing.Bitmap(640, 360, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
$g = [System.Drawing.Graphics]::FromImage($resized)
$g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$g.DrawImage($bmp, 0, 0, 640, 360)
$g.Dispose()
$bmp.Dispose()

$resized.Save($dst, [System.Drawing.Imaging.ImageFormat]::Png)
$resized.Dispose()

Write-Host "Restaurado com sucesso em: $dst (640x360)"

