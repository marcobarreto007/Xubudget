@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUZINHA FINANCE AI - Launcher

cls
echo ========================================
echo    XUZINHA FINANCE AI DASHBOARD
echo    Created by Marco Barreto for Ana Paula
echo ========================================
echo.

echo [CHK] Verificando dependencias...
python --version >nul 2>&1 || (echo [ERRO] Python nao encontrado & pause & exit /b 1)
node --version >nul 2>&1   || (echo [ERRO] Node.js nao encontrado & pause & exit /b 1)
echo [OK] Python e Node encontrados.

echo.
echo [CHK] Verificando Ollama (IA Local)...
curl -s http://127.0.0.1:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
  echo [INFO] Ollama nao detectado. Iniciando servidor...
  start "Ollama" cmd /c "ollama serve"
  timeout /t 3 >nul
) else (
  echo [OK] Ollama ativo.
)

echo.
cd /d "%~dp0"

echo [START] Backend (porta 5002)...
cd services\pi2_assistant
start "Xubudget Backend" cmd /k "python pi2_server.py"
timeout /t 5 /nobreak >nul

echo [START] Xuzinha Dashboard...
cd ..\..\xuzinha_dashboard
if not exist "node_modules" (
  echo [SETUP] Instalando dependencias React...
  call npm install
)
start "Xuzinha Dashboard" cmd /k "npm start"

timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo   XUZINHA FINANCE AI RODANDO!
echo   Backend:  http://127.0.0.1:5002
echo   Frontend: http://localhost:3000
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
