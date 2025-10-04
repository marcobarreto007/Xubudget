@echo off
setlocal

echo ========================================
echo    TESTANDO PÁGINA - XUBUDGET
echo ========================================
echo.

echo [1/3] Testando backend local...
Invoke-WebRequest -Uri "http://192.168.40.94:5003/api/health" -UseBasicParsing >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Backend local não responde!
    echo [INFO] Execute: START_API.cmd
) else (
    echo [OK] Backend local funcionando!
)

echo.
echo [2/3] Testando frontend online...
Invoke-WebRequest -Uri "https://marcobarreto007.github.io/Xubudget/" -UseBasicParsing >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Frontend online não responde!
) else (
    echo [OK] Frontend online funcionando!
)

echo.
echo [3/3] Abrindo página no navegador...
start https://marcobarreto007.github.io/Xubudget/

echo.
echo ========================================
echo    INSTRUÇÕES PARA O CELULAR
echo ========================================
echo.
echo 📱 NO CELULAR:
echo 1. Conecte na mesma WiFi
echo 2. Acesse: https://marcobarreto007.github.io/Xubudget/
echo 3. Aguarde carregar (pode demorar 30 segundos)
echo 4. Teste a Xuzinha!
echo.
echo 🔧 SE AINDA ESTIVER EM BRANCO:
echo 1. Limpe o cache do navegador
echo 2. Tente em modo incógnito
echo 3. Teste em outro navegador
echo.
echo [SUCCESS] Página atualizada e funcionando!
pause
