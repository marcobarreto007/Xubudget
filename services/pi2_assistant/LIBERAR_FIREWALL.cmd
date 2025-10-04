@echo off
echo ========================================
echo    LIBERAR FIREWALL - XUBUDGET
echo ========================================
echo.
echo [INFO] Liberando portas para acesso mobile...
echo.

REM Liberar porta 5003 (Backend)
netsh advfirewall firewall add rule name="Xubudget Backend 5003" dir=in action=allow protocol=TCP localport=5003
if errorlevel 1 (
    echo [ERRO] Falha ao liberar porta 5003
) else (
    echo [OK] Porta 5003 liberada!
)

REM Liberar porta 3000 (Frontend)
netsh advfirewall firewall add rule name="Xubudget Frontend 3000" dir=in action=allow protocol=TCP localport=3000
if errorlevel 1 (
    echo [ERRO] Falha ao liberar porta 3000
) else (
    echo [OK] Porta 3000 liberada!
)

echo.
echo [SUCCESS] Firewall configurado!
echo [INFO] Agora teste no celular:
echo        - Backend: http://192.168.40.94:5003/api/health
echo        - Frontend: https://marcobarreto007.github.io/Xubudget/
echo.
pause
