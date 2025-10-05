@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title TESTE DE MODAL - XUZINHA

cls
echo ========================================
echo    TESTE DE MODAL - XUZINHA DASHBOARD
echo ========================================
echo.

echo [1/3] Verificando servidor...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Servidor nao esta rodando!
    echo [INFO] Execute: npm start
    pause
    exit /b 1
)
echo [OK] Servidor ativo.

echo.
echo [2/3] Abrindo navegador...
start http://localhost:3000

echo.
echo [3/3] Instrucoes de teste:
echo.
echo ========================================
echo   TESTE DE MODAL INICIADO
echo ========================================
echo.
echo [PASSOS PARA TESTAR]
echo 1. Vá para a aba "Manage"
echo 2. Clique no botão "Force Open Modal" (vermelho)
echo 3. Deve aparecer um modal com fundo vermelho
echo 4. Se não aparecer, verifique o console (F12)
echo 5. Teste também "Test Add Expense" (azul)
echo.
echo [DEBUG]
echo - Abra o console do navegador (F12)
echo - Procure por logs "ExpenseForm render"
echo - Verifique se isOpen está true
echo.
echo [PROBLEMAS COMUNS]
echo - Modal não aparece: problema de z-index
echo - Modal aparece mas não clica: problema de eventos
echo - Console mostra erro: problema de JavaScript
echo.
pause
endlocal
