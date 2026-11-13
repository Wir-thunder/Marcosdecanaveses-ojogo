[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
$targets = @(
    @{ Path = "silkscreen/Silkscreen-Regular.ttf"; Out = "Silkscreen-Regular.ttf" },
    @{ Path = "pirataone/PirataOne-Regular.ttf"; Out = "PirataOne-Regular.ttf" },
    @{ Path = "almendra/Almendra-Regular.ttf"; Out = "Almendra-Regular.ttf" }
)

foreach ($t in $targets) {
    try {
        $url = "https://raw.githubusercontent.com/google/fonts/main/ofl/" + $t.Path
        $dest = "$PSScriptRoot\..\Assets\Fonts\" + $t.Out
        Invoke-WebRequest -Uri $url -OutFile $dest -TimeoutSec 10
        Write-Host "Downloaded $($t.Out): $((Get-Item $dest).Length) bytes"
    } catch {
        Write-Host "Failed $($t.Path): $_"
    }
}
