@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - SISTEMA SIMPLES

cls
echo ========================================
echo    XUBUDGET - SISTEMA SIMPLES
echo ========================================
echo.

echo [1/2] Iniciando Backend...
start "Xubudget Backend" cmd /k "python pi2_server.py"
timeout /t 3 /nobreak >nul

echo [2/2] Iniciando Frontend React...
cd services\xubudget-dashboard
start "Xubudget Frontend" cmd /k "npm start"

echo.
echo ========================================
echo   XUBUDGET RODANDO!
echo   Backend:  http://localhost:3000
echo   Frontend: http://localhost:3001
echo ========================================
echo.
echo [INFO] Aguarde o React compilar...
echo [INFO] O navegador abrira automaticamente
echo.
timeout /t 5 /nobreak >nul
start http://localhost:3001
pause
endlocal
