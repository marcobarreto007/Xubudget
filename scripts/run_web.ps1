param(
  [switch]$NoBackend
)

Write-Host "[Xubudget] Iniciando Web..." -ForegroundColor Cyan

# 1) Backend (opcional)
if (-not $NoBackend) {
  try {
    $health = Invoke-WebRequest -UseBasicParsing -Uri "http://127.0.0.1:5005/healthz" -TimeoutSec 2
    if ($health.StatusCode -eq 200) {
      Write-Host "[Xubudget] Backend já está no ar (5005)." -ForegroundColor Green
    } else { throw "status $($health.StatusCode)" }
  } catch {
    Write-Host "[Xubudget] Subindo backend em 5005..." -ForegroundColor Yellow
    Start-Process powershell -ArgumentList "-NoProfile","-ExecutionPolicy","Bypass","-Command","cd '$PSScriptRoot\..\services\pi2_assistant'; python -m uvicorn pi2_server:app --host 127.0.0.1 --port 5005 --reload" -WindowStyle Minimized
    Start-Sleep -Seconds 2
  }
}

# 2) Flutter Web
Set-Location -Path "$PSScriptRoot\..\mobile_app"
Write-Host "[Xubudget] Executando Flutter Web no Chrome..." -ForegroundColor Yellow
flutter run -d chrome
