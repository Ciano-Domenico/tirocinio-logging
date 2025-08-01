# generate-traffic-simple.ps1
Write-Host "Generazione traffico di test..." -ForegroundColor Green

$endpoints = @("/app1/", "/app2/", "/app3/", "/app3/error", "/nonexistent")

for ($i = 1; $i -le 20; $i++) {
    $endpoint = $endpoints | Get-Random
    Write-Host "[$i/20] Testing: $endpoint"

    try {
        Invoke-RestMethod -Uri "http://localhost$endpoint" -TimeoutSec 3 | Out-Null
    }
    catch {
        # Ignora errori
    }

    Start-Sleep -Seconds 1
}

Write-Host "Test completato!" -ForegroundColor Green
