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