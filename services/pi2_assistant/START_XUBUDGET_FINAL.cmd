@echo off
chcp 65001 >nul

title XUBUDGET - Launcher Final

cls
echo ========================================
echo    XUBUDGET - Iniciando Sistema
echo ========================================
echo.

echo [CHK] Verificando dependencias...
python --version
if %errorlevel% neq 0 (
  echo [ERRO] Python nao encontrado
  pause
  exit /b 1
)
echo [OK] Python encontrado.

echo.
echo [CHK] Verificando Ollama (IA Local)...
curl -s http://127.0.0.1:11434/api/tags
if %errorlevel% neq 0 (
  echo [INFO] Ollama nao detectado. Iniciando servidor...
  start "Ollama" cmd /c "ollama serve"
  timeout /t 3
) else (
  echo [OK] Ollama ativo.
)

echo.
cd /d "%~dp0"

echo [START] Backend (porta 5003)...
cd services\xubudget_api
start "Xubudget Backend" cmd /k "python main.py"
timeout /t 3

echo.
echo [START] Frontend Dashboard...
cd ..\xubudget-dashboard
start "Xubudget Frontend" cmd /k "npm start"

echo.
echo ========================================
echo   XUBUDGET RODANDO
echo   Backend:  http://127.0.0.1:5003
echo   Frontend: http://localhost:3000
echo ========================================
echo.
echo [INFO] Aguarde o React compilar...
echo [INFO] O navegador abrira automaticamente
echo.
pause
