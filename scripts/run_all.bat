@echo off
setlocal
chcp 65001>nul
set ROOT=%~dp0..\

REM WHY: sobe backend (8000) e web (3000) com 1 clique
pushd "%ROOT%services\pi2_assistant"
if not exist ".venv" (py -3 -m venv .venv)
call .venv\Scripts\activate.bat
pip install -r requirements.txt --disable-pip-version-check
start "XUZINHA BACKEND :8000" cmd /c "py app.py"

pushd xuzinha_dashboard
if exist package.json (
  call npm i
  start "XUZINHA WEB :3000" cmd /c "npm run dev -- --port 3000"
) else (
  echo [WARN] Front nao encontrado em services\pi2_assistant\xuzinha_dashboard
)
popd & popd

echo [OK] Backend http://127.0.0.1:8000  |  Web http://127.0.0.1:3000
endlocal