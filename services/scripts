@echo off
echo ========================================
echo    XUBUDGET - DESENVOLVIMENTO COMPLETO
echo ========================================

echo.
echo 1. Parando processos existentes...
taskkill /F /IM python.exe 2>nul
taskkill /F /IM node.exe 2>nul

echo.
echo 2. Verificando Ollama...
ollama ps >nul 2>&1
if errorlevel 1 (
    echo    Iniciando Ollama...
    start /B ollama serve
    timeout /t 3 >nul
)

echo.
echo 3. Verificando modelo DeepSeek...
ollama list | findstr "deepseek-r1:7b" >nul
if errorlevel 1 (
    echo    Baixando modelo DeepSeek-R1 7B...
    ollama pull deepseek-r1:7b
)

echo.
echo 4. Iniciando Backend (porta 8000)...
cd /d "%~dp0.."
start /B python app.py

echo.
echo 5. Aguardando backend inicializar...
timeout /t 5 >nul

echo.
echo 6. Testando backend...
curl -s http://127.0.0.1:8000/ >nul
if errorlevel 1 (
    echo    ❌ Backend não respondeu!
    pause
    exit /b 1
) else (
    echo    ✅ Backend funcionando!
)

echo.
echo 7. Executando smoke test...
powershell -ExecutionPolicy Bypass -File scripts\smoke_test.ps1

echo.
echo ========================================
echo    SISTEMA PRONTO!
echo    Frontend: http://127.0.0.1:8000
echo    API: http://127.0.0.1:8000/api
echo ========================================
echo.
echo Pressione qualquer tecla para abrir o navegador...
pause >nul
start http://127.0.0.1:8000
