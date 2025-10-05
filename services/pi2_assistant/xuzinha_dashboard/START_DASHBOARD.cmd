@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUZINHA DASHBOARD - Launcher

cls
echo ========================================
echo    XUZINHA FINANCE AI DASHBOARD
echo ========================================
echo.

echo [1/3] Verificando dependencias...
node --version >nul 2>&1 || (echo [ERRO] Node.js nao encontrado & pause & exit /b 1)
echo [OK] Node.js encontrado.

echo.
echo [2/3] Verificando pasta do projeto...
if not exist "package.json" (
    echo [ERRO] package.json nao encontrado!
    echo [INFO] Certifique-se de estar na pasta xuzinha_dashboard
    pause
    exit /b 1
)
echo [OK] Projeto encontrado.

echo.
echo [3/3] Iniciando Xuzinha Dashboard...
echo [INFO] URL: http://localhost:3000
echo [INFO] Pressione Ctrl+C para parar
echo.

start "Xuzinha Dashboard" cmd /k "npm start"

echo.
echo ========================================
echo   XUZINHA DASHBOARD INICIADO!
echo   URL: http://localhost:3000
echo ========================================
echo.
echo [FEATURES]
echo - Receipt Capture com OCR
echo - Chat com Xuzinha IA
echo - Dashboard Financeiro
echo - Edicao Manual de Despesas
echo - Sistema de Orcamento
echo.
echo [INFO] O navegador abrira automaticamente
echo [INFO] Xuzinha esta esperando por voce! 💜
echo.
pause
endlocal
