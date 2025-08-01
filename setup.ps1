# setup.ps1 - Script PowerShell per Windows
Write-Host "🚀 Setup del progetto di tirocinio: ELK Stack vs Loki+Grafana" -ForegroundColor Green
Write-Host "=============================================================="

# Crea la struttura delle directory
Write-Host "📁 Creazione struttura directory..." -ForegroundColor Yellow
$directories = @(
    "nginx-proxy\logs",
    "logstash\pipeline",
    "logstash\config",
    "loki",
    "promtail",
    "grafana\provisioning\datasources",
    "grafana\provisioning\dashboards",
    "prometheus",
    "apps\simple-node-app"
)

foreach ($dir in $directories) {
    New-Item -ItemType Directory -Path $dir -Force | Out-Null
}

# Crea il file logstash.yml
Write-Host "⚙️  Creazione configurazione Logstash..." -ForegroundColor Yellow
@'
http.host: "0.0.0.0"
xpack.monitoring.elasticsearch.hosts: [ "http://elasticsearch:9200" ]
path.config: /usr/share/logstash/pipeline
path.logs: /usr/share/logstash/logs
'@ | Out-File -FilePath "logstash\config\logstash.yml" -Encoding UTF8

# Crea configurazione Prometheus
Write-Host "⚙️  Creazione configurazione Prometheus..." -ForegroundColor Yellow
@'
global:
  scrape_interval: 15s
  evaluation_interval: 15s

rule_files:
  # - "first_rules.yml"
  # - "second_rules.yml"

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
      - targets: ['localhost:9090']

  - job_name: 'nginx-proxy'
    static_configs:
      - targets: ['nginx-proxy:8080']
    metrics_path: '/nginx_status'
    scrape_interval: 5s

  - job_name: 'node-exporter'
    static_configs:
      - targets: ['node-exporter:9100']
'@ | Out-File -FilePath "prometheus\prometheus.yml" -Encoding UTF8

Write-Host "✅ Setup completato!" -ForegroundColor Green
Write-Host ""
Write-Host "🔥 Per avviare il progetto:" -ForegroundColor Cyan
Write-Host "   1. docker-compose up -d" -ForegroundColor White
Write-Host "   2. Attendi che tutti i servizi siano pronti (circa 2-3 minuti)" -ForegroundColor White
Write-Host "   3. Genera traffico: .\generate-traffic.ps1" -ForegroundColor White
Write-Host ""
Write-Host "🌐 URL dei servizi:" -ForegroundColor Cyan
Write-Host "   - Reverse Proxy:  http://localhost" -ForegroundColor White
Write-Host "   - Kibana (ELK):   http://localhost:5601" -ForegroundColor White
Write-Host "   - Grafana (Loki): http://localhost:3000 (admin/admin123)" -ForegroundColor White
Write-Host "   - Prometheus:     http://localhost:9090" -ForegroundColor White
Write-Host "   - Loki:           http://localhost:3100" -ForegroundColor White
