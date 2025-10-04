@echo off
setlocal

echo ========================================
echo    XUBUDGET - BACKEND COMPLETO
echo ========================================
echo.

REM Pasta da API
set "API_DIR=%~dp0services\xubudget_api"
cd /d "%API_DIR%" || goto :err

echo [INFO] Iniciando backend Xubudget...
echo [INFO] IP: 192.168.40.94:5003
echo [INFO] Frontend: https://marcobarreto007.github.io/Xubudget/
echo [INFO] Health: http://192.168.40.94:5003/api/health
echo.

REM Verificar Python
python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python não encontrado! Instale Python 3.8+
    pause
    goto :eof
)

REM Verificar se já tem as dependências instaladas
python -c "import fastapi, uvicorn, pydantic, requests" >nul 2>&1
if errorlevel 1 (
    echo [SETUP] Instalando dependências básicas...
    pip install fastapi uvicorn[standard] pydantic requests --quiet
) else (
    echo [INFO] Dependências já instaladas!
)

REM Criar diretório de logs
if not exist "logs" mkdir logs

REM Matar processos existentes
taskkill /f /im python.exe /fi "WINDOWTITLE eq Xubudget API" >nul 2>&1

echo [START] Iniciando servidor...
echo [INFO] Pressione Ctrl+C para parar
echo.

REM Iniciar servidor em background
start "Xubudget API" cmd /c "python main.py"

echo [SUCCESS] Backend iniciado!
echo [INFO] Sua família pode acessar:
echo        - Frontend: https://marcobarreto007.github.io/Xubudget/
echo        - Backend: http://192.168.40.94:5003/api/health
echo.
echo [INFO] Mantenha este terminal aberto!
pause
goto :eof

:err
echo [ERRO] Falha ao iniciar backend!
echo [INFO] Verifique se a pasta services\xubudget_api existe
pause
