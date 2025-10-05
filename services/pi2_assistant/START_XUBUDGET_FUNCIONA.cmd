@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - FUNCIONA DE VERDADE

cls
echo ========================================
echo    XUBUDGET - INICIANDO SISTEMA
echo ========================================
echo.

echo [1/4] Verificando Python...
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao encontrado!
    pause
    exit /b 1
)
echo [OK] Python encontrado!

echo.
echo [2/4] Verificando Node.js...
node --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Node.js nao encontrado!
    pause
    exit /b 1
)
echo [OK] Node.js encontrado!

echo.
echo [3/4] Iniciando Backend...
cd /d "%~dp0services\xubudget_api"
start "Xubudget Backend" cmd /k "python main.py"
timeout /t 3 /nobreak >nul

echo.
echo [4/4] Iniciando Frontend React...
cd /d "%~dp0services\xubudget-dashboard"
start "Xubudget Frontend" cmd /k "npm start"

echo.
echo ========================================
echo   XUBUDGET RODANDO!
echo   Backend:  http://localhost:5003
echo   Frontend: http://localhost:3000
echo ========================================
echo.
echo [INFO] Aguarde o React compilar...
echo [INFO] O navegador abrira automaticamente
echo.
pause
endlocal
