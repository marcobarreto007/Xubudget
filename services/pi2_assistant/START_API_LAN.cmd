@echo off
setlocal

REM Start API bound to 0.0.0.0:5002 for LAN/mobile testing
set "API_DIR=%~dp0"
set "API_DIR=%API_DIR:~0,-1%"
cd /d "%API_DIR%" || goto :err

REM Ensure venv and minimal deps
if not exist ".venv\Scripts\python.exe" (
  echo [SETUP] Criando venv e instalando deps...
  py -3 -m venv .venv || goto :err
  .venv\Scripts\python.exe -m pip install -U pip || goto :err
  if exist requirements.txt .venv\Scripts\python.exe -m pip install -r requirements.txt || goto :err
  .venv\Scripts\python.exe -m pip install fastapi uvicorn[standard] python-multipart || goto :err
)

if not exist "logs" mkdir logs

set "USE_OLLAMA=1"
set "OLLAMA_HOST=http://127.0.0.1:11434"
set "OLLAMA_MODEL=llama3"

echo [API] Iniciando FastAPI (LAN) em http://0.0.0.0:5002 ...
title Xubudget API (LAN)
.venv\Scripts\python.exe -m uvicorn --host 0.0.0.0 --port 5002 --reload --reload-exclude new_frontend --reload-exclude .venv pi2_server:app
goto :eof

:err
echo [ERRO] Falha no setup. Verifique Python (py -3 --version) e permissoes.
pause

