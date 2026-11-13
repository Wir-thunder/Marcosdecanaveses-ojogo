Add-Type -AssemblyName System.Drawing
$text = "A Loja do Alquimista · Poção de Cura · Tâmega · Marco de Canaveses · Não há poções · 100 ouro · Atenção"
$fonts = @("MedievalSharp.ttf", "Silkscreen-Regular.ttf", "Almendra-Regular.ttf", "PirataOne-Regular.ttf")

foreach ($f in $fonts) {
    $p = "$PSScriptRoot\..\Assets\Fonts\$f"
    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    $pfc.AddFontFile($p)
    $family = $pfc.Families[0]
    $font = New-Object System.Drawing.Font($family, 14)
    Write-Host "Font: $f -> Name: $($family.Name)"
    $pfc.Dispose()
}

