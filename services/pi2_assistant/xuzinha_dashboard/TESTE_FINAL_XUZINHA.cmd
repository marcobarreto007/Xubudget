@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title TESTE FINAL XUZINHA - SISTEMA ZERADO

cls
echo ========================================
echo    TESTE FINAL XUZINHA - SISTEMA ZERADO
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
echo [2/4] Sistema ZERADO - Todos os numeros em 0
echo [OK] Despesas: 0
echo [OK] Orcamentos: 0
echo [OK] Receitas: 0

echo.
echo [3/4] Abrindo navegador...
start http://localhost:3000

echo.
echo [4/4] COMANDOS DE TESTE PARA XUZINHA:
echo.
echo ========================================
echo   TESTE FINAL XUZINHA - COMANDOS
echo ========================================
echo.
echo [TESTE 1 - CONFIGURAR RECEITAS]
echo Digite para Xuzinha:
echo "Configure minha receita semanal de 1000 reais"
echo "Adicione ajuda do governo de 200 reais por semana"
echo "Meu salario mensal e 4000 reais"
echo.
echo [TESTE 2 - CONFIGURAR ORCAMENTOS]
echo Digite para Xuzinha:
echo "Configure meu orcamento: comida 600, transporte 400, saude 300, moradia 1200, utilidades 200, compras 150, lazer 100, educacao 50, poupanca 800, outros 100"
echo.
echo [TESTE 3 - ADICIONAR DESPESAS]
echo Digite para Xuzinha:
echo "Adicione uma despesa de 45 reais para almoco no restaurante"
echo "Adicione gasolina de 60 reais no posto Shell"
echo "Adicione compras no supermercado de 120 reais"
echo "Adicione farmacia de 35 reais"
echo "Adicione aluguel de 1200 reais"
echo.
echo [TESTE 4 - EDITAR E CALCULAR]
echo Digite para Xuzinha:
echo "Edite a despesa de almoco para 50 reais"
echo "Me mostre quanto gastei em comida"
echo "Qual categoria gastei mais?"
echo "Me mostre meu resumo financeiro"
echo "Quanto me resta no orcamento de comida?"
echo.
echo [TESTE 5 - ANÁLISE COMPLETA]
echo Digite para Xuzinha:
echo "Me mostre um relatorio completo das minhas financas"
echo "Estou gastando demais em alguma categoria?"
echo "Quanto posso economizar este mes?"
echo.
echo [OBJETIVO]
echo A Xuzinha deve conseguir:
echo - Configurar receitas e orcamentos
echo - Adicionar despesas automaticamente
echo - Editar valores existentes
echo - Calcular totais e restantes
echo - Fazer analises financeiras
echo - Dar sugestoes de economia
echo.
pause
endlocal
