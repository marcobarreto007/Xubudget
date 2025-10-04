@echo off
setlocal

REM Start pi2_server:app on 127.0.0.1:5003 (no fallback)
set "API_DIR=%~dp0"
set "API_DIR=%API_DIR:~0,-1%"
cd /d "%API_DIR%" || goto :err

if not exist ".venv\Scripts\python.exe" (
  echo [SETUP] Criando venv e instalando deps...
  py -3 -m venv .venv || goto :err
  .venv\Scripts\python.exe -m pip install -U pip || goto :err
  if exist requirements.txt .venv\Scripts\python.exe -m pip install -r requirements.txt || goto :err
  .venv\Scripts\python.exe -m pip install fastapi uvicorn[standard] python-multipart || goto :err
)

set "HOST=127.0.0.1"
set "PORT=5003"
echo [API] Iniciando FastAPI (pi2_server:app) em http://%HOST%:%PORT% ...
title Xubudget API (pi2_server 5003)
.venv\Scripts\python.exe -m uvicorn pi2_server:app --host %HOST% --port %PORT% --reload --reload-exclude new_frontend --reload-exclude .venv
goto :eof

:err
echo [ERRO] Falha no setup de API PI2.
pause

