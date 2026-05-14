# ================================
# Roku Dev Mode Monitor
# Connects to: 192.168.1.196:8085
# User: rokudev
# Pass: whit
# Logs button presses + video traces
# ================================

$ip = "192.168.1.196"
$port = 8085

$target = "$ip`:$port"
$logFile = Join-Path $PSScriptRoot ("rokudev_" + (Get-Date -Format "yyyyMMdd_HHmmss") + ".log")

Write-Host "=== Roku Dev Monitor ===" -ForegroundColor Cyan
Write-Host ("Target: {0}" -f $target)
Write-Host ("Saving log to: {0}" -f $logFile)
Write-Host "Press Ctrl+C to stop"
Write-Host "========================`n"

# Create empty log
"" | Out-File $logFile

try {
    $client = New-Object System.Net.Sockets.TcpClient
    $client.Connect($ip, $port)

    $stream = $client.GetStream()
    $writer = New-Object System.IO.StreamWriter($stream)
    $reader = New-Object System.IO.StreamReader($stream)

    Write-Host "Connected to Roku debug console!" -ForegroundColor Green

    while ($client.Connected) {
        if ($stream.DataAvailable) {
            $line = $reader.ReadLine()

            if ($line -ne $null) {

                # Highlight button presses
                if ($line -match "ButtonPressed") {
                    Write-Host $line -ForegroundColor Yellow
                }
                # Highlight video playback traces
                elseif ($line -match "Video" -or $line -match "play" -or $line -match "stream") {
                    Write-Host $line -ForegroundColor Cyan
                }
                else {
                    Write-Host $line
                }

                # Log everything
                $line | Out-File -FilePath $logFile -Append
            }
        }

        Start-Sleep -Milliseconds 10
    }
}
catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($reader) { $reader.Close() }
    if ($writer) { $writer.Close() }
    if ($stream) { $stream.Close() }
    if ($client) { $client.Close() }

    Write-Host "Disconnected." -ForegroundColor Yellow
    Write-Host ("`nLog saved to: {0}" -f $logFile) -ForegroundColor Green
    Write-Host "Share this file or paste its contents.`n" -ForegroundColor Green
}
