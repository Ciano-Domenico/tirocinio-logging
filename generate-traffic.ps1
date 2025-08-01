# generate-traffic.ps1 - Script PowerShell per generare traffico
Write-Host "🚦 Generazione traffico di test per Nginx Reverse Proxy" -ForegroundColor Green
Write-Host "======================================================="

# Array di endpoint e user agent
$endpoints = @(
    "/app1/",
    "/app1/info",
    "/app1/health",
    "/app2/",
    "/app3/",
    "/app3/health",
    "/app3/slow",
    "/app3/error",
    "/app3/memory",
    "/nonexistent",
    "/api/v1/test"
)

$userAgents = @(
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36",
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36",
    "curl/7.68.0",
    "PostmanRuntime/7.28.4"
)

function Generate-Requests {
    for ($i = 1; $i -le 50; $i++) {
        $endpoint = $endpoints | Get-Random
        $userAgent = $userAgents | Get-Random
        $requestId = "req-$(Get-Date -Format 'yyyyMMddHHmmss')-$i"

        Write-Host "[$i/50] Requesting: $endpoint" -ForegroundColor Yellow

        try {
            $headers = @{
                'User-Agent'   = $userAgent
                'X-Request-ID' = $requestId
            }

            Invoke-RestMethod -Uri "http://localhost$endpoint" -Headers $headers -TimeoutSec 5 -ErrorAction SilentlyContinue | Out-Null
        }
        catch {
            # Ignora errori (404, 500, etc. sono voluti per i test)
        }

        # Pausa casuale tra 0.5 e 2 secondi
        $sleepTime = (Get-Random -Minimum 5 -Maximum 20) / 10
        Start-Sleep -Seconds $sleepTime
    }
}

# Controlla se i servizi sono attivi
Write-Host "🔍 Verifica servizi..." -ForegroundColor Cyan
try {
    Invoke-RestMethod -Uri "http://localhost/health" -TimeoutSec 5 | Out-Null
    Write-Host "✅ Servizi attivi, inizio generazione traffico..." -ForegroundColor Green
}
catch {
    Write-Host "❌ Nginx proxy non raggiungibile su http://localhost" -ForegroundColor Red
    Write-Host "   Assicurati che i servizi siano attivi: docker-compose up -d" -ForegroundColor Yellow
    exit 1
}

Write-Host ""

# Genera traffico in loop continuo
while ($true) {
    Write-Host "🔄 Nuovo ciclo di richieste - $(Get-Date)" -ForegroundColor Cyan
    Generate-Requests
    Write-Host "⏸️  Pausa 10 secondi prima del prossimo ciclo..." -ForegroundColor Magenta
    Write-Host ""
    Start-Sleep -Seconds 10
}
