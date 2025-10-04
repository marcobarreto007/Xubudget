@echo off
setlocal

echo ========================================
echo    XUBUDGET - START RAPIDO
echo ========================================
echo.

REM Pasta da API
set "API_DIR=%~dp0services\xubudget_api"
cd /d "%API_DIR%" || goto :err

echo [INFO] Iniciando backend Xubudget...
echo [INFO] IP: 192.168.40.94:5003
echo [INFO] Frontend: https://marcobarreto007.github.io/Xubudget/
echo.

REM Matar processos existentes
taskkill /f /im python.exe /fi "WINDOWTITLE eq Xubudget API" >nul 2>&1

echo [START] Iniciando servidor...
echo.

REM Iniciar servidor diretamente
start "Xubudget API" cmd /c "python main.py"

echo [SUCCESS] Backend iniciado!
echo [INFO] Sua família pode acessar:
echo        - Frontend: https://marcobarreto007.github.io/Xubudget/
echo        - Backend: http://192.168.40.94:5003/api/health
echo.
echo [INFO] Pressione qualquer tecla para fechar...
pause >nul
goto :eof

:err
echo [ERRO] Falha ao iniciar backend!
echo [INFO] Verifique se a pasta services\xubudget_api existe
pause
