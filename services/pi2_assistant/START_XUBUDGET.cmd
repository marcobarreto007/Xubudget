@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - Launcher

cls
echo ========================================
echo    XUBUDGET - Iniciando Sistema
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

echo [START] Backend (porta 5003)...
cd services\xubudget_api
start "Xubudget Backend" cmd /k "python main.py"
timeout /t 5 /nobreak >nul

echo [START] Frontend (porta 3000)...
cd ..\xubudget-web
if not exist "node_modules" (
  echo [SETUP] Instalando dependencias npm...
  call npm install
)
set "REACT_APP_API_URL=http://127.0.0.1:5003/api"
start "Xubudget Frontend" cmd /k "npm start"

timeout /t 5 /nobreak >nul
start http://localhost:3000

echo.
echo ========================================
echo   XUBUDGET RODANDO
echo   Backend:  http://127.0.0.1:5003
echo   Frontend: http://localhost:3000
echo ========================================
echo.
pause
endlocal