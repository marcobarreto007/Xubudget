param()
Write-Host "[Xubudget] Resetando ambiente Web..." -ForegroundColor Cyan

try {
  Get-Process -Name dart,flutter,chrome,msedge,python -ErrorAction SilentlyContinue | Stop-Process -Force
} catch {}

Start-Sleep -Seconds 1

Set-Location -Path "$PSScriptRoot\..\mobile_app"

Write-Host "[Xubudget] flutter clean" -ForegroundColor Yellow
flutter clean | Out-Host

Write-Host "[Xubudget] Removendo artefatos .dart_tool e plugins" -ForegroundColor Yellow
Remove-Item -Recurse -Force .dart_tool,.flutter-plugins-dependencies -ErrorAction SilentlyContinue

Write-Host "[Xubudget] flutter pub get" -ForegroundColor Yellow
flutter pub get | Out-Host

Write-Host "[Xubudget] Reset concluído." -ForegroundColor Green
