@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - FUNCIONA!

cls
echo ========================================
echo    XUBUDGET - SISTEMA FUNCIONANDO
echo ========================================
echo.

echo [1/1] Iniciando Xubudget Completo...
start "Xubudget" cmd /k "python pi2_server.py"

echo.
echo ========================================
echo   XUBUDGET RODANDO!
echo   URL: http://localhost:5002
echo ========================================
echo.
echo [INFO] O navegador abrira automaticamente
echo [INFO] Sistema completo com Flutter Web
echo.
pause
endlocal
