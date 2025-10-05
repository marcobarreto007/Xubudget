@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title TESTE XUZINHA IA - SISTEMA COMPLETO

cls
echo ========================================
echo    TESTE XUZINHA IA - SISTEMA COMPLETO
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
echo [2/4] Verificando Ollama (IA Local)...
curl -s http://localhost:11434/api/tags >nul 2>&1
if %errorlevel% neq 0 (
    echo [AVISO] Ollama nao detectado - Xuzinha usara modo offline
) else (
    echo [OK] Ollama ativo - Xuzinha com IA completa
)

echo.
echo [3/4] Abrindo navegador...
start http://localhost:3000

echo.
echo [4/4] Instrucoes de teste da Xuzinha:
echo.
echo ========================================
echo   TESTE XUZINHA IA INICIADO
echo ========================================
echo.
echo [TESTE 1 - CHAT DA XUZINHA]
echo 1. Clique no icone da Xuzinha (canto inferior direito)
echo 2. Digite: "Olá Xuzinha, me mostre minhas despesas"
echo 3. Verifique se ela responde e mostra as despesas
echo.
echo [TESTE 2 - EDIÇÃO VIA CHAT]
echo 1. Digite: "Adicione uma despesa de 50 reais para comida"
echo 2. Verifique se ela adiciona automaticamente
echo 3. Digite: "Edite a primeira despesa para 60 reais"
echo 4. Verifique se ela edita corretamente
echo.
echo [TESTE 3 - ANÁLISE FINANCEIRA]
echo 1. Digite: "Me mostre um resumo das minhas despesas"
echo 2. Verifique se ela mostra gráficos e análises
echo 3. Digite: "Qual categoria gasto mais?"
echo 4. Verifique se ela analisa os dados
echo.
echo [TESTE 4 - RECEIPT CAPTURE]
echo 1. Clique no botao da camera (canto inferior direito)
echo 2. Tire uma foto de um recibo
echo 3. Verifique se ela extrai os dados automaticamente
echo.
echo [DEBUG]
echo - Abra o console (F12) para ver logs da Xuzinha
echo - Verifique se há erros de conexão com Ollama
echo - Teste comandos em português e inglês
echo.
pause
endlocal
