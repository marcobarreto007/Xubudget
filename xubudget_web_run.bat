@echo off
setlocal
title Xubudget Web Runner

REM Backend settings
set ROOT=%~dp0
set BACKEND_URL=http://127.0.0.1:5001

REM Start FastAPI backend (127.0.0.1:5001) in a new window from project root
start "Xubudget Backend" powershell -NoProfile -ExecutionPolicy Bypass -Command "cd '%ROOT%'; $env:PYTHONPATH='%ROOT%'; python -m uvicorn services.pi2_assistant.pi2_server:app --host 127.0.0.1 --port 5001 --reload"

REM Small delay to let backend start
timeout /t 2 /nobreak >nul

REM Start Flutter web-server on fixed port 51333 (served at http://127.0.0.1:51333) and pass AI_BASE_URL
cd /d "%~dp0mobile_app"
flutter run -d web-server --web-hostname 127.0.0.1 --web-port 51333 --dart-define=AI_BASE_URL=%BACKEND_URL%

echo.
echo If the browser can't connect, open: http://127.0.0.1:51333  | Backend: %BACKEND_URL%
echo Keep this window open while using the app.
pause
