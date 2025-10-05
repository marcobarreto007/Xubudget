@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUZINHA FINANCE AI - Dashboard

cls
echo ========================================
echo    XUZINHA FINANCE AI DASHBOARD
echo    Created by Marco Barreto for Ana Paula
echo ========================================
echo.

echo [1/3] Verificando dependencias...
node --version >nul 2>&1 || (echo [ERRO] Node.js nao encontrado & pause & exit /b 1)
echo [OK] Node.js encontrado.

echo.
echo [2/3] Instalando dependencias...
if not exist "node_modules" (
    echo [SETUP] Instalando dependencias npm...
    call npm install || (echo [ERRO] npm install falhou & pause & exit /b 1)
) else (
    echo [OK] Dependencias ja instaladas!
)

echo.
echo [3/3] Iniciando Xuzinha Dashboard...
echo [INFO] Dashboard sera aberto em http://localhost:3000
echo [INFO] Xuzinha esta pronta para ajudar! 💜
echo.

start "Xuzinha Dashboard" cmd /k "npm start"

echo.
echo ========================================
echo   XUZINHA FINANCE AI RODANDO!
echo   URL: http://localhost:3000
echo ========================================
echo.
echo [FEATURES]
echo - Receipt Capture com OCR
echo - Chat com Xuzinha IA
echo - Dashboard Financeiro
echo - Metas e Orçamentos
echo - Analytics Avançados
echo.
echo [INFO] O navegador abrira automaticamente
echo [INFO] Xuzinha esta esperando por você! 💜
echo.
pause
endlocal
