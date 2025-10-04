@echo off
echo ===== CORRECAO XUBUDGET =====

REM Parar processos
echo [0] Parando processos antigos...
taskkill /F /IM python.exe /T 2>nul
taskkill /F /IM node.exe /T 2>nul

echo [1] Verificando servidor corrigido...
REM O passo de substituir o servidor foi feito no passo anterior.

echo [2] Preparando ambiente...
cd /d "C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant"

REM Criar venv se não existir
if not exist ".venv" (
    echo    - Criando venv...
    py -3 -m venv .venv
)

REM Instalar dependências
echo    - Instalando dependencias Python...
.venv\Scripts\pip install -r requirements.txt >nul

echo [3] Iniciando servidor API...
start "Xubudget API" .venv\Scripts\python -m uvicorn server_app:app --host 127.0.0.1 --port 5002

echo [4] Aguardando API (10 segundos)...
timeout /t 10 >nul

echo [5] Testando saude da API...
curl http://127.0.0.1:5002/api/healthz

echo [6] Iniciando frontend...
cd new_frontend
if not exist "node_modules" (
    echo    - Instalando dependencias Node (npm install)...
    npm install
)

set REACT_APP_API_BASE=http://127.0.0.1:5002
start "Xubudget Web" npm start

echo.
echo ===== CONCLUIDO =====
echo.
echo Suas aplicacoes devem estar no ar:
echo API Docs: http://127.0.0.1:5002/docs
echo Web App:  http://localhost:3000/#/dashboard
echo.
