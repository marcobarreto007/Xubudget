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