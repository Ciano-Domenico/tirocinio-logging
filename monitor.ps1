# monitor.ps1 - Script PowerShell per monitoraggio
Write-Host "📊 Monitor dei Log - ELK vs Loki" -ForegroundColor Green
Write-Host "================================="

function Check-ELK {
    Write-Host "🔍 ELK Stack Status:" -ForegroundColor Cyan

    try {
        $health = Invoke-RestMethod -Uri "http://localhost:9200/_cluster/health" -TimeoutSec 5
        Write-Host "  Elasticsearch: $($health.status)" -ForegroundColor White
    }
    catch {
        Write-Host "  Elasticsearch: DOWN" -ForegroundColor Red
    }

    try {
        $kibanaResponse = Invoke-WebRequest -Uri "http://localhost:5601" -TimeoutSec 5
        Write-Host "  Kibana: $($kibanaResponse.StatusCode)" -ForegroundColor White
    }
    catch {
        Write-Host "  Kibana: DOWN" -ForegroundColor Red
    }

    try {
        $logCount = Invoke-RestMethod -Uri "http://localhost:9200/nginx-logs-*/_count" -TimeoutSec 5
        Write-Host "  Log count: $($logCount.count)" -ForegroundColor White
    }
    catch {
        Write-Host "  Log count: 0 (o servizio non disponibile)" -ForegroundColor Yellow
    }

    Write-Host ""
}

function Check-Loki {
    Write-Host "🔍 Loki Stack Status:" -ForegroundColor Cyan

    try {
        $lokiResponse = Invoke-WebRequest -Uri "http://localhost:3100/ready" -TimeoutSec 5
        Write-Host "  Loki: $($lokiResponse.StatusCode)" -ForegroundColor White
    }
    catch {
        Write-Host "  Loki: DOWN" -ForegroundColor Red
    }

    try {
        $grafanaResponse = Invoke-WebRequest -Uri "http://localhost:3000/api/health" -TimeoutSec 5
        Write-Host "  Grafana: $($grafanaResponse.StatusCode)" -ForegroundColor White
    }
    catch {
        Write-Host "  Grafana: DOWN" -ForegroundColor Red
    }

    Write-Host ""
}

function Check-Nginx {
    Write-Host "🔍 Nginx Proxy Status:" -ForegroundColor Cyan

    $accessLogPath = "nginx-proxy\logs\access.log"
    $errorLogPath = "nginx-proxy\logs\error.log"

    if (Test-Path $accessLogPath) {
        $accessLogs = (Get-Content $accessLogPath).Count
        Write-Host "  Access logs: $accessLogs lines" -ForegroundColor White

        if ($accessLogs -gt 0) {
            $lastLog = Get-Content $accessLogPath -Tail 1 | ConvertFrom-Json -ErrorAction SilentlyContinue
            if ($lastLog) {
                Write-Host "  Last request: $($lastLog.timestamp)" -ForegroundColor White
            }
        }
    }
    else {
        Write-Host "  Access logs: File non trovato" -ForegroundColor Yellow
    }

    if (Test-Path $errorLogPath) {
        $errorLogs = (Get-Content $errorLogPath).Count
        Write-Host "  Error logs: $errorLogs lines" -ForegroundColor White
    }
    else {
        Write-Host "  Error logs: File non trovato" -ForegroundColor Yellow
    }

    Write-Host ""
}

# Loop di monitoraggio
while ($true) {
    Clear-Host
    Write-Host "📊 Monitor dei Log - ELK vs Loki - $(Get-Date)" -ForegroundColor Green
    Write-Host "=========================================="
    Write-Host ""

    Check-Nginx
    Check-ELK
    Check-Loki

    Write-Host "💡 Comandi utili:" -ForegroundColor Magenta
    Write-Host "  - Ctrl+C per uscire" -ForegroundColor White
    Write-Host "  - .\generate-traffic.ps1 per generare traffico" -ForegroundColor White
    Write-Host "  - docker-compose logs [service] per vedere i log" -ForegroundColor White
    Write-Host ""

    Start-Sleep -Seconds 5
}
