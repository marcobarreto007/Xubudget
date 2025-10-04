@echo off
setlocal enabledelayedexpansion

REM One-click: API on LAN + Frontend over HTTPS for mobile testing
set "ROOT=%~dp0"
cd /d "%ROOT%" || goto :err

REM ==== 0) Detect LAN IPv4 (pt/en locales) ====
set "LAN_IP="
for /f "tokens=2 delims=:" %%a in ('ipconfig ^| findstr /r /c:"IPv4 Address" /c:"Endere.* IPv4"') do (
  set ipraw=%%a
  set ipraw=!ipraw: =!
  for /f "tokens=1 delims=(" %%b in ("!ipraw!") do set cand=%%b
  if "!cand:~0,4!"=="192." set LAN_IP=!cand!
  if "!cand:~0,3!"=="10." set LAN_IP=!cand!
  if "!cand:~0,4!"=="172." set LAN_IP=!cand!
  if defined LAN_IP goto :ip_found
)
:ip_found
if not defined LAN_IP (
  echo [ERRO] Nao consegui detectar o IP da LAN. Informe manualmente e reexecute.
  echo Ex.: 192.168.0.23
  pause
  goto :eof
)
echo LAN_IP = %LAN_IP%

REM Export EXTRA_CORS_ORIGINS so API allows https://LAN_IP:3000
set "EXTRA_CORS_ORIGINS=https://%LAN_IP%:3000,http://%LAN_IP%:3000"

REM ==== 1) Start API on 0.0.0.0:5002 in a new window ====
start "Xubudget API (LAN)" cmd /k "cd /d %ROOT% && set EXTRA_CORS_ORIGINS=%EXTRA_CORS_ORIGINS% && START_API_LAN.cmd"

REM Small wait before hitting frontend
timeout /t 3 >nul 2>&1

REM ==== 2) Frontend build and HTTPS static serve ====
set "FRONT=%ROOT%new_frontend"
if not exist "%FRONT%" (
  echo [ERRO] Pasta do frontend nao encontrada: %FRONT%
  goto :err
)
cd /d "%FRONT%" || goto :err

if not exist certs mkdir certs

REM Install local CA (mkcert) and create cert for localhost + LAN IP
call npx --yes mkcert -install
call npx --yes mkcert -key-file certs\dev-key.pem -cert-file certs\dev.pem localhost 127.0.0.1 ::1 %LAN_IP%

REM Build frontend
call npm run build || goto :err

REM Serve build over HTTPS on 3000
start "Xubudget WEB (HTTPS)" cmd /k "cd /d %FRONT% && npx --yes http-server ./build -S -C certs\dev.pem -K certs\dev-key.pem -p 3000"

REM ==== 3) Open dashboard and print mobile URL ====
start https://localhost:3000/#/dashboard
echo.
echo ============================================================
echo  Abra no celular (mesma rede Wi-Fi):
echo      https://%LAN_IP%:3000/#/dashboard
echo  Aceite o certificado local quando solicitado.
echo ============================================================
echo.
goto :eof

:err
echo [ERRO] Falha no processo. Verifique Node.js/NPM e Python.
pause

