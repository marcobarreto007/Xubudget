@echo off
setlocal
set ROOT=%~dp0
set API_DIR=%ROOT%
set FRONT_DIR=%API_DIR%new_frontend
cd /d "%FRONT_DIR%"

if not exist "node_modules" (
  echo [WEB] Instalando dependencias (npm install)...
  call npm install || goto :err
)

if not exist "%API_DIR%logs" mkdir "%API_DIR%logs"
set LOG_FILE=%API_DIR%logs\web.log
echo [LOG] Salvando logs em %LOG_FILE%

set "BROWSER=none"
set "PORT=3000"
set "REACT_APP_API_BASE=http://127.0.0.1:5002"
echo [WEB] API base: %REACT_APP_API_BASE%
echo [WEB] Iniciando React em http://localhost:%PORT% ...
call npm start
goto :eof

:err
echo [ERRO] Necessita Node.js/NPM. Verifique com: node -v e npm -v
pause
