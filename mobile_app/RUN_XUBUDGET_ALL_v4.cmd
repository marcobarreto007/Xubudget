@echo off
setlocal
REM WHY: Adicionado PAUSE para depurar por que as janelas fecham sozinhas
set ROOT=C:\Users\marco\Xubudget\Xubudget
set BACK=%ROOT%\services\pi2_assistant
set FRONT=%ROOT%\mobile_app
set PORT=5210

REM Fecha Chrome pra n??o herdar aba de debug
taskkill /F /IM chrome.exe >nul 2>&1

REM Garante baseUrl do Flutter -> FastAPI local
set "DART=%FRONT%\lib\ui\xu_dashboard_page.dart"
powershell -NoProfile -Command "$f='%DART%'; if (Test-Path $f) { $t = Get-Content -Raw $f; $t = $t -replace 'static const String baseUrl = \'http://[^\'']+\'\'';, 'static const String baseUrl = \'http://localhost:5001\'';'; Set-Content -Path $f -Value $t -Encoding UTF8 "

REM Sobe backend FastAPI
start "Xubudget Backend" cmd /k "cd /d %BACK% && uvicorn pi2_server:app --host 127.0.0.1 --port 5001 --reload & PAUSE"

REM Espera backend ficar healthy
:wait_api
curl -s http://127.0.0.1:5001/healthz | findstr /i "\"status\":\"healthy\"" >nul
if errorlevel 1 (timeout /t 1 >nul & goto wait_api)

REM Descobre flutter no PATH; se n??o tiver, usa caminho padr??o
set "FLUTTER=flutter"
where flutter >nul 2>&1 || (if exist "C:\src\flutter\bin\flutter.bat" set "FLUTTER=C:\src\flutter\bin\flutter.bat")

REM Sobe Flutter Web (APP) na porta fixa
start "Xubudget Frontend" cmd /k "cd /d %FRONT% && \"%FLUTTER%\" run -d chrome --web-hostname=localhost --web-port=%PORT% & PAUSE"

REM Espera a porta 5210 estar escutando de verdade
powershell -NoProfile -Command "while(-not (Test-NetConnection -ComputerName localhost -Port %PORT% -InformationLevel Quiet)){ Start-Sleep -s 1 }"

REM Agora abre o APP (n??o a p??gina de debug)
start "" "http://localhost:%PORT%"

echo ================================================
echo Frontend: http://localhost:%PORT%
echo Backend : http://127.0.0.1:5001
echo ===============================================
endlocal
