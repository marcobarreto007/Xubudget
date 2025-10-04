@echo off
setlocal

echo ========================================
echo    TESTE CELULAR - XUBUDGET
echo ========================================
echo.

echo [INFO] Testando conectividade...
echo.

REM Testar backend
echo [TESTE 1] Backend Health Check...
curl -s http://192.168.40.94:5003/api/health
if errorlevel 1 (
    echo [ERRO] Backend não responde!
    echo [INFO] Execute: START_API.cmd
    pause
    goto :eof
) else (
    echo [OK] Backend funcionando!
)

echo.
echo [TESTE 2] Backend Expenses...
curl -s http://192.168.40.94:5003/api/expenses
if errorlevel 1 (
    echo [ERRO] API de despesas não responde!
) else (
    echo [OK] API de despesas funcionando!
)

echo.
echo ========================================
echo    INSTRUÇÕES PARA O CELULAR
echo ========================================
echo.
echo 1. CONECTE O CELULAR NA MESMA REDE WiFi
echo.
echo 2. TESTE O BACKEND NO CELULAR:
echo    http://192.168.40.94:5003/api/health
echo    (Deve mostrar: {"status":"healthy"})
echo.
echo 3. ACESSE O FRONTEND:
echo    https://marcobarreto007.github.io/Xubudget/
echo.
echo 4. TESTE A XUZINHA:
echo    - Clique no botão da Xuzinha
echo    - Digite: "gastei 25 no cinema"
echo    - Confirme: "sim claro"
echo.
echo ========================================
echo    SE NÃO FUNCIONAR
echo ========================================
echo.
echo 1. Execute como ADMINISTRADOR:
echo    LIBERAR_FIREWALL.cmd
echo.
echo 2. Verifique se o celular está na mesma rede
echo.
echo 3. Desative temporariamente o antivírus
echo.
echo 4. Teste no PC primeiro:
echo    http://192.168.40.94:5003/api/health
echo.
pause
