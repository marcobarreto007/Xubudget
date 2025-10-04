@echo off
setlocal
REM WHY: padronizar tudo e evitar abrir a porta de debug no navegador
set ROOT=C:\Users\marco\Xubudget\Xubudget
set BACK=%ROOT%\services\pi2_assistant
set FRONT=%ROOT%\mobile_app
set PORT=5210

REM Fechar Chrome pra não grudar na aba de debug
taskkill /F /IM chrome.exe >nul 2>&1

REM WHY: garantir baseUrl correta no Flutter (apontar para o FastAPI)
set "DART=%FRONT%\lib\ui\xu_dashboard_page.dart"
powershell -NoProfile -Command ^
  "$f='%DART%'; if (Test-Path $f) { $t = Get-Content -Raw $f; $t = $t -replace 'static const String baseUrl = \'http://[^'']+\'\'', 'static const String baseUrl = \'http://localhost:5001\''; Set-Content -Path $f -Value $t -Encoding UTF8 }"

REM WHY: subir backend FastAPI
start "Xubudget Backend" cmd /k ^
 "cd /d %BACK% && uvicorn pi2_server:app --host 127.0.0.1 --port 5001 --reload"

REM Esperar backend ficar healthy
:wait_backend
curl -s http://127.0.0.1:5001/healthz | findstr /i "status":"healthy" >nul
if errorlevel 1 (timeout /t 1 >nul & goto wait_backend)

REM WHY: subir Flutter Web como APP (porta fixa), não a URL de debug
start "Xubudget Frontend" cmd /k ^
 "cd /d %FRONT% && flutter run -d chrome --web-hostname=localhost --web-port=%PORT%"

REM Abrir direto o APP correto
timeout /t 5 >nul
start "" "http://localhost:%PORT%"

echo ===============================================
echo Frontend: http://localhost:%PORT%
echo Backend : http://127.0.0.1:5001
echo Se fechar as janelas, o sistema para.
echo ===============================================
endlocal