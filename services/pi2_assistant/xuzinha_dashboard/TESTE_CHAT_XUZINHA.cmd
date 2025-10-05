@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title TESTE CHAT XUZINHA - CAIXA DE DIALOGO

cls
echo ========================================
echo    TESTE CHAT XUZINHA - CAIXA DE DIALOGO
echo ========================================
echo.

echo [1/4] Verificando servidor...
curl -s http://localhost:3000 >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERRO] Servidor nao esta rodando!
    echo [INFO] Execute: npm start
    pause
    exit /b 1
)
echo [OK] Servidor ativo.

echo.
echo [2/4] Abrindo navegador...
start http://localhost:3000

echo.
echo [3/4] INSTRUCOES DE TESTE:
echo.
echo ========================================
echo   TESTE CHAT XUZINHA - INSTRUCOES
echo ========================================
echo.
echo [PASSO 1 - ENCONTRAR O BOTAO]
echo 1. Procure pelo icone da Xuzinha (canto inferior direito)
echo 2. Deve ser um botao roxo com coracao
echo 3. Se nao encontrar, procure por "Toggle Chat" (amarelo)
echo.
echo [PASSO 2 - ABRIR O CHAT]
echo 1. Clique no icone da Xuzinha
echo 2. Deve aparecer uma caixa VERMELHA do lado direito
echo 3. Se nao aparecer, clique em "Toggle Chat"
echo.
echo [PASSO 3 - TESTAR O CHAT]
echo 1. Digite: "Ola Xuzinha"
echo 2. Pressione Enter ou clique em Send
echo 3. Verifique se ela responde
echo.
echo [PASSO 4 - COMANDOS DE TESTE]
echo Digite estes comandos:
echo - "Adicione uma despesa de 50 reais para comida"
echo - "Me mostre minhas despesas"
echo - "Configure minha receita de 1000 reais"
echo.
echo [PROBLEMAS COMUNS]
echo - Botao nao aparece: problema de CSS
echo - Chat nao abre: problema de estado
echo - Chat abre mas nao funciona: problema de JavaScript
echo - Chat abre mas e transparente: problema de z-index
echo.
echo [DEBUG]
echo - Abra o console (F12)
echo - Procure por erros JavaScript
echo - Verifique se showChat esta true
echo - Teste o botao "Toggle Chat"
echo.
pause
endlocal
