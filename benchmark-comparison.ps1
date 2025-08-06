# benchmark-comparison.ps1
Write-Host "Benchmark ELK vs Loki" -ForegroundColor Green
Write-Host "====================="
Write-Host ""

# Test Elasticsearch
Write-Host "Test Elasticsearch..." -ForegroundColor Yellow
$esQueryTimes = @()
for ($i = 1; $i -le 3; $i++) {
  try {
    $start = Get-Date
    $response = Invoke-RestMethod "http://localhost:9200/tirocinio-nginx-*/_search?size=10"
    $end = Get-Date
    $time = ($end - $start).TotalMilliseconds
    $esQueryTimes += $time
    Write-Host "  Query $i : $([math]::Round($time, 2))ms" -ForegroundColor Gray
  }
  catch {
    Write-Host "  Query $i : ERROR" -ForegroundColor Red
  }
  Start-Sleep 1
}

if ($esQueryTimes.Count -gt 0) {
  $esAvgTime = ($esQueryTimes | Measure-Object -Average).Average
  Write-Host "  Media ES: $([math]::Round($esAvgTime, 2))ms" -ForegroundColor White
}
else {
  $esAvgTime = 0
}

Write-Host ""

# Test Loki
Write-Host "Test Loki..." -ForegroundColor Yellow
$lokiQueryTimes = @()
for ($i = 1; $i -le 3; $i++) {
  try {
    $start = Get-Date
    $response = Invoke-RestMethod "http://localhost:3100/loki/api/v1/query?query={job=`"nginx-proxy`"}"
    $end = Get-Date
    $time = ($end - $start).TotalMilliseconds
    $lokiQueryTimes += $time
    Write-Host "  Query $i : $([math]::Round($time, 2))ms" -ForegroundColor Gray
  }
  catch {
    Write-Host "  Query $i : ERROR - $($_.Exception.Message)" -ForegroundColor Red
  }
  Start-Sleep 1
}

if ($lokiQueryTimes.Count -gt 0) {
  $lokiAvgTime = ($lokiQueryTimes | Measure-Object -Average).Average
  Write-Host "  Media Loki: $([math]::Round($lokiAvgTime, 2))ms" -ForegroundColor White
}
else {
  $lokiAvgTime = 0
}

Write-Host ""

# Genera traffico
Write-Host "Generazione traffico..." -ForegroundColor Yellow
$endpoints = @("/app1/", "/app2/", "/app3/", "/nonexistent")
$requests = 0

for ($i = 1; $i -le 15; $i++) {
  $endpoint = $endpoints | Get-Random
  try {
    Invoke-RestMethod "http://localhost$endpoint" | Out-Null
    $requests++
  }
  catch {
    # Ignora errori 404/500
  }
  Start-Sleep 0.5
}

Write-Host "  Richieste inviate: $requests" -ForegroundColor White
Write-Host ""

# Aspetta processing
Write-Host "Aspettando elaborazione..." -ForegroundColor Yellow
Start-Sleep 15
Write-Host ""

# Conta log Elasticsearch
Write-Host "Conteggio log..." -ForegroundColor Yellow
try {
  $esCount = Invoke-RestMethod "http://localhost:9200/tirocinio-nginx-*/_count"
  Write-Host "  Elasticsearch: $($esCount.count) documenti" -ForegroundColor White
  $esLogs = $esCount.count
}
catch {
  Write-Host "  Elasticsearch: Errore conteggio" -ForegroundColor Red
  $esLogs = 0
}

# Dimensione file log
if (Test-Path "nginx-proxy\logs\access.log") {
  $logSize = (Get-Item "nginx-proxy\logs\access.log").Length / 1MB
  Write-Host "  File log: $([math]::Round($logSize, 2)) MB" -ForegroundColor White
}

Write-Host ""

# Risorse memoria
Write-Host "Uso memoria..." -ForegroundColor Yellow

$elkMemory = 0
$lokiMemory = 0

# ELK containers
$elkContainers = @("elasticsearch", "logstash", "kibana")
foreach ($container in $elkContainers) {
  try {
    $stats = docker stats $container --no-stream --format "{{.MemUsage}}"
    if ($stats -match "(\d+\.?\d*)MiB") {
      $mem = [float]$matches[1]
      $elkMemory += $mem
      Write-Host "  $container : $mem MB" -ForegroundColor Gray
    }
  }
  catch {
    Write-Host "  $container : Errore stats" -ForegroundColor Red
  }
}

# Loki containers
$lokiContainers = @("loki", "promtail", "grafana")
foreach ($container in $lokiContainers) {
  try {
    $stats = docker stats $container --no-stream --format "{{.MemUsage}}"
    if ($stats -match "(\d+\.?\d*)MiB") {
      $mem = [float]$matches[1]
      $lokiMemory += $mem
      Write-Host "  $container : $mem MB" -ForegroundColor Gray
    }
  }
  catch {
    Write-Host "  $container : Errore stats" -ForegroundColor Red
  }
}

Write-Host ""
Write-Host "Totali memoria:" -ForegroundColor Cyan
Write-Host "  ELK Stack:  $([math]::Round($elkMemory, 1)) MB" -ForegroundColor White
Write-Host "  Loki Stack: $([math]::Round($lokiMemory, 1)) MB" -ForegroundColor White

Write-Host ""

# Risultati finali
Write-Host "RISULTATI BENCHMARK" -ForegroundColor Green
Write-Host "==================="
Write-Host ""

Write-Host "Performance Query:" -ForegroundColor Cyan
Write-Host "  ELK:  $([math]::Round($esAvgTime, 2)) ms" -ForegroundColor White
Write-Host "  Loki: $([math]::Round($lokiAvgTime, 2)) ms" -ForegroundColor White
Write-Host ""

Write-Host "Uso Memoria:" -ForegroundColor Cyan
Write-Host "  ELK:  $([math]::Round($elkMemory, 1)) MB" -ForegroundColor White
Write-Host "  Loki: $([math]::Round($lokiMemory, 1)) MB" -ForegroundColor White
Write-Host ""

Write-Host "Log Processati:" -ForegroundColor Cyan
Write-Host "  Elasticsearch: $esLogs documenti" -ForegroundColor White
Write-Host ""

# Crea risultati CSV
$csvContent = @"
Metrica,ELK,Loki
Query_Time_ms,$([math]::Round($esAvgTime, 2)),$([math]::Round($lokiAvgTime, 2))
Memory_MB,$([math]::Round($elkMemory, 1)),$([math]::Round($lokiMemory, 1))
Log_Count,$esLogs,N/A
"@

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$csvFile = "benchmark-results-$timestamp.csv"
$csvContent | Out-File -FilePath $csvFile -Encoding UTF8

Write-Host "File CSV salvato: $csvFile" -ForegroundColor Green
Write-Host ""

# Conclusioni
Write-Host "CONCLUSIONI:" -ForegroundColor Cyan

if ($esAvgTime -gt 0 -and $lokiAvgTime -gt 0) {
  if ($esAvgTime -lt $lokiAvgTime) {
    Write-Host "- ELK ha query piu veloci" -ForegroundColor Yellow
  }
  else {
    Write-Host "- Loki ha query piu veloci" -ForegroundColor Yellow
  }
}

if ($elkMemory -gt $lokiMemory) {
  Write-Host "- Loki usa meno memoria" -ForegroundColor Yellow
}
else {
  Write-Host "- ELK usa meno memoria" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Benchmark completato!" -ForegroundColor Green
Write-Host "Usa il file CSV per la tua tesi." -ForegroundColor Cyan
