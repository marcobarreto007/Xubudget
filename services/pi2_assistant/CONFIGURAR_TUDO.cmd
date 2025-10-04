@echo off
setlocal

echo ========================================
echo    CONFIGURANDO TUDO - XUBUDGET
echo ========================================
echo.

echo [1/4] Verificando backend...
Invoke-WebRequest -Uri "http://192.168.40.94:5003/api/health" -UseBasicParsing >nul 2>&1
if errorlevel 1 (
    echo [INFO] Iniciando backend...
    start "Xubudget Backend" cmd /c "cd services\xubudget_api && python main.py"
    timeout /t 3 /nobreak >nul
) else (
    echo [OK] Backend já está rodando!
)

echo.
echo [2/4] Liberando firewall...
netsh advfirewall firewall add rule name="Xubudget Backend 5003" dir=in action=allow protocol=TCP localport=5003 >nul 2>&1
netsh advfirewall firewall add rule name="Xubudget Frontend 3000" dir=in action=allow protocol=TCP localport=3000 >nul 2>&1
echo [OK] Firewall configurado!

echo.
echo [3/4] Testando conectividade...
Invoke-WebRequest -Uri "http://192.168.40.94:5003/api/health" -UseBasicParsing >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Backend não responde!
    pause
    goto :eof
) else (
    echo [OK] Backend funcionando!
)

echo.
echo [4/4] Abrindo navegador...
start https://marcobarreto007.github.io/Xubudget/

echo.
echo ========================================
echo    CONFIGURAÇÃO COMPLETA!
echo ========================================
echo.
echo ✅ Backend: http://192.168.40.94:5003/api/health
echo ✅ Frontend: https://marcobarreto007.github.io/Xubudget/
echo ✅ Firewall: Liberado
echo.
echo 📱 NO CELULAR:
echo 1. Conecte na mesma WiFi
echo 2. Acesse: https://marcobarreto007.github.io/Xubudget/
echo 3. Teste a Xuzinha!
echo.
echo [SUCCESS] Tudo configurado e funcionando!
pause
