@echo off
echo ========================================
echo    XUBUDGET AI - SISTEMA COMPLETO
echo ========================================
echo.

echo [1/3] Parando processos existentes...
taskkill /F /IM python.exe 2>nul
taskkill /F /IM node.exe 2>nul
echo.

echo [2/3] Iniciando Backend (FastAPI + Ollama)...
cd services\pi2_assistant
start /B python app.py
timeout /t 3 /nobreak >nul
echo.

echo [3/3] Iniciando Frontend (React)...
cd ..\xuzinha_dashboard
start /B npm run dev -- --port 3000
timeout /t 5 /nobreak >nul
echo.

echo ========================================
echo    SISTEMA RODANDO!
echo ========================================
echo Backend:  http://127.0.0.1:8000
echo Frontend: http://localhost:3000
echo ========================================
echo.
echo Pressione qualquer tecla para parar...
pause >nul

echo.
echo Parando sistema...
taskkill /F /IM python.exe 2>nul
taskkill /F /IM node.exe 2>nul
echo Sistema parado!
