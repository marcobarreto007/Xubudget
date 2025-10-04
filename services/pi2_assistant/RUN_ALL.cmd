@echo off
setlocal

REM Simple, robust launcher for API (:5002) and Web (:3000)
set "API_DIR=%~dp0"
set "API_DIR=%API_DIR:~0,-1%"
set "FRONT_DIR=%API_DIR%\new_frontend"
set "API_HOST=127.0.0.1"
set "API_PORT=5002"
set "FRONT_PORT=3000"

echo [KILL] Closing anything on ports %API_PORT% and %FRONT_PORT% (if any)...
for /f "tokens=5" %%p in ('netstat -ano ^| find ":%API_PORT% " ^| find "LISTENING"') do taskkill /F /PID %%p >nul 2>&1
for /f "tokens=5" %%p in ('netstat -ano ^| find ":%FRONT_PORT% " ^| find "LISTENING"') do taskkill /F /PID %%p >nul 2>&1

echo [API] Starting...
start "Xubudget API %API_PORT%" cmd /k "cd /d "%API_DIR%" && START_API.cmd"

echo [WEB] Starting...
if exist "%FRONT_DIR%" (
  start "Xubudget Web %FRONT_PORT%" cmd /k "cd /d "%FRONT_DIR%" && set "BROWSER=none" && set "PORT=%FRONT_PORT%" && set "REACT_APP_API_BASE=http://%API_HOST%:%API_PORT%" && npm start"
) else (
  echo [ERROR] Frontend folder not found: %FRONT_DIR%
)

REM Give servers a moment, then open URLs
timeout /t 4 >nul
start "" http://localhost:%FRONT_PORT%/#/dashboard
start "" http://%API_HOST%:%API_PORT%/docs
echo [DONE] RUN_ALL started both servers.
