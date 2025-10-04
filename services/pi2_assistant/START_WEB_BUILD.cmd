@echo off
setlocal

REM Build React and serve build with http-server + proxy fallback to API
set "ROOT=%~dp0"
set "FRONT=%ROOT%new_frontend"
cd /d "%FRONT%" || goto :err

if not exist node_modules (
  echo [WEB] Installing dependencies...
  call npm install || goto :err
)

echo [WEB] Building production bundle...
call npm run build || goto :err

echo [WEB] Starting static server on http://localhost:3000 with API proxy -> http://127.0.0.1:5002
start "Xubudget WEB (build)" cmd /k "cd /d %FRONT% && npx http-server ./build -p 3000 -P http://127.0.0.1:5002 --gzip --brotli"
goto :eof

:err
echo [ERRO] Falha ao iniciar o web build.
pause

