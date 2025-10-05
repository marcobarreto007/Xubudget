@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - Launcher Simples

cls
echo ========================================
echo    XUBUDGET - Iniciando Sistema
echo ========================================
echo.

echo [CHK] Verificando dependencias...
python --version >nul 2>&1 || (echo [ERRO] Python nao encontrado & pause & exit /b 1)
echo [OK] Python encontrado.

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
start "Xubudget Backend" cmd /c "python main.py"
timeout /t 3 /nobreak >nul

echo.
echo [START] Frontend Flutter...
cd ..\..\mobile_app
start "Xubudget Frontend" cmd /c "flutter run -d chrome"

timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo   XUBUDGET RODANDO
echo   Backend:  http://127.0.0.1:5003
echo   Frontend: Flutter Web (Chrome)
echo ========================================
echo.
echo [INFO] Aguarde o Flutter compilar...
echo [INFO] O Chrome abrira automaticamente
echo.
pause
endlocal
