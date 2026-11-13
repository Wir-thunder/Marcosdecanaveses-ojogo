$iso = [System.Text.Encoding]::GetEncoding("iso-8859-1")
$utf8 = [System.Text.Encoding]::UTF8

$bad = "PRAÃ‡A CENTRAL DE CANAVESES, CoraÃ§Ã£o histÃ³rico da vila. Liga a tua Loja Ã  Taverna do Vale, Floresta do TÃ¢mega, Mina Antiga e RuÃ­nas de TongÃ³briga."
$bytes = $iso.GetBytes($bad)
$fixed = $utf8.GetString($bytes)
Write-Output "ORIGINAL: $bad"
Write-Output "FIXED:    $fixed"

