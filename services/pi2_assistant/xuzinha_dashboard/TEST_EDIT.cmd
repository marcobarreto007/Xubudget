@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title TESTE DE EDICAO - XUZINHA

cls
echo ========================================
echo    TESTE DE EDICAO - XUZINHA DASHBOARD
echo ========================================
echo.

echo [1/2] Verificando servidor...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Servidor nao esta rodando!
    echo [INFO] Execute: npm start
    pause
    exit /b 1
)
echo [OK] Servidor ativo.

echo.
echo [2/2] Abrindo navegador para teste...
echo [INFO] Vá para a aba "Manage" e teste a edição
echo [INFO] Verifique o console do navegador (F12)
echo.

start http://localhost:3000

echo.
echo ========================================
echo   TESTE DE EDICAO INICIADO
echo   URL: http://localhost:3000
echo ========================================
echo.
echo [INSTRUCOES]
echo 1. Vá para a aba "Manage"
echo 2. Clique no botão de editar (✏️) de uma despesa
echo 3. Verifique se o formulário abre com os dados
echo 4. Modifique os valores e salve
echo 5. Verifique se a despesa foi atualizada
echo.
echo [DEBUG]
echo - Abra o console do navegador (F12)
echo - Clique no botão "Test Console Log"
echo - Verifique os logs no console
echo.
pause
endlocal
