# GEMINI.md — Xubudget FULL FIX (docs + scripts + README)

## GOAL
Organizar Xubudget para stack Web: **FastAPI :8000 + React :3000 + Ollama deepseek-r1:7b**.
- Mover scripts para **/scripts** (raiz)
- Criar **/docs/repo_analysis.md** (MSAR)
- Atualizar **README.md** (não é Flutter; é Web + FastAPI)
- Adicionar **.gitignore** agressivo
- Não tocar no código funcional já existente

## FILES

### create: /scripts/run_all.bat
```bat
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

create: /scripts/smoke_test.ps1
$ErrorActionPreference = "Stop"
$base = "http://127.0.0.1:8000"

"GET /" | Write-Host
Invoke-RestMethod "$base/" | ConvertTo-Json -Depth 4

"POST /api/chat/xuzinha listar" | Write-Host
Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"listar despesas por categoria"}' | ConvertTo-Json -Depth 8

"POST /api/chat/xuzinha aumentar Food em 20" | Write-Host
Invoke-RestMethod "$base/api/chat/xuzinha" -Method Post -ContentType "application/json" -Body '{"user_id":"smoke","message":"aumente Food em 20"}' | ConvertTo-Json -Depth 8

"GET /api/expenses/totals" | Write-Host
Invoke-RestMethod "$base/api/expenses/totals" | ConvertTo-Json -Depth 8

create: /docs/repo_analysis.md
# Xubudget — Repo Analysis (MSAR)

**Branch:** `main` (⚠️ não existe `master`).  
**Stack:** React :3000 + FastAPI :8000 + Ollama `deepseek-r1:7b`.  
**Objetivo:** IA age (db.*), resposta curta, UI atualiza.

## DIVERGENCE
- README antigo fala Flutter/porta 5005; runtime é Web + 8000 + DeepSeek.
- Front não refazia fetch após db.* → parecia “cego”.
- Agente ruminava → faltava anti-loop/finalização JSON.
- Codex usou `master` e quebrou.

## PATH_FIX
- Backend 8000 com anti-loop e `db.get_expenses/db.update_expense/db.set_category/db.reset`.
- Front chama `/api/chat/xuzinha`; se `used_tools` contém `db.*`, refetch de `/api/expenses/totals`.
- Ollama com `format:"json"`, `repeat_penalty` e `stop` para cortar papagaio.
- README corrigido.

## Contratos
POST `/api/chat/xuzinha` → `{"final_answer","used_tools"}`  
GET  `/api/expenses/totals` → `{"totals":{...}}`  
GET  `/` → `{"ok":true,"tools":[...]}`

## Dev rápido
```bash
ollama pull deepseek-r1:7b
cd services/pi2_assistant && pip install -r requirements.txt && python app.py   # :8000
cd services/pi2_assistant/xuzinha_dashboard && npm i && npm run dev -- --port 3000


### update: /README.md  (substituir conteúdo)
```md
# Xubudget AI — Web (React) + FastAPI + Ollama (DeepSeek)

**Stack:** Front React :3000 + Backend FastAPI :8000 + Ollama `deepseek-r1:7b`.  
O fluxo Flutter antigo está obsoleto.

## Como rodar
```bash
# Modelo
ollama pull deepseek-r1:7b

# Backend
cd services/pi2_assistant
pip install -r requirements.txt
python app.py   # http://127.0.0.1:8000

# Frontend (se presente)
cd xuzinha_dashboard
npm i
npm run dev -- --port 3000

Endpoints

POST /api/chat/xuzinha → {"user_id","message"} => {"final_answer","used_tools"}

GET /api/expenses/totals

GET / (health + tools)

Scripts úteis

scripts/run_all.bat — sobe tudo

scripts/smoke_test.ps1 — smoke de API

Observações

Respostas curtas (≤ 2 frases).

Pedidos de despesas usam db.*; UI refaz fetch após db.update_expense|db.set_category|db.reset.

Branch padrão: main.


### upsert: /.gitignore
```gitignore
# Node
node_modules/
dist/
build/
.vite/
.next/
coverage/
*.log
npm-debug.log*
yarn-*.log

# Python
__pycache__/
*.pyc
*.pyo
*.pyd
*.egg-info/
.venv/
env/
virtualenv/
.pytest_cache/

# IDE/OS
.vscode/
.idea/
.DS_Store
Thumbs.db

# Cache/temp
.tmp/
temp/
tmp/
.cache/
*.bak
*.old
*.orig

# Projeto Xubudget
data/
uploads/
*.sqlite
*.db

# Mídia pesada
*.mp4
*.mov
*.avi
*.mkv
*.psd
*.ai
*.sketch

# Front caches
xuzinha_dashboard/.cache/
xuzinha_dashboard/.turbo/
xuzinha_dashboard/.parcel-cache/

MOVE (se existirem)

mover services/pi2_assistant/scripts/run_all.bat → /scripts/run_all.bat

mover services/pi2_assistant/scripts/smoke_test.ps1 → /scripts/smoke_test.ps1

GIT

add/commit/push:

mensagem: chore(repo): docs + scripts na raiz + README Web/FastAPI

```