Xubudget — Repo Analysis (MSAR)

Branch padrão: main (⚠️ não existe master).
Stack alvo: React (3000) + FastAPI (8000) + Ollama deepseek-r1:7b.
Objetivo: IA age (db.*) com respostas curtas e UI atualiza na hora.

1) DIVERGENCE

README/scripts antigos falam Flutter/Qwen/5005; runtime real é Web + FastAPI 8000 + DeepSeek.

Front não refaz fetch após ações → parece “cego”.

Agente às vezes rumina (loops / textão) → falta anti-loop + finalização em JSON.

Codex errou por git ref master inexistente → branch é main.

2) PATH_FIX (mínimo que resolve)

Backend (8000)

Orquestrador com anti-loop (máx. 3 passos; sem repetir a mesma tool).

Roteador de intenção (PT/EN/ES): db.get_expenses, db.update_expense, db.set_category, db.reset.

Saída JSON estrita { final_answer, used_tools } e clamp (≤ 2 frases / 180 chars).

Endpoints: GET / (health) e GET /api/expenses/totals.

Frontend

API_BASE = http://127.0.0.1:8000.

Chat usa POST /api/chat/xuzinha e, se used_tools contém db.update_expense|db.set_category|db.reset, faz refetch de GET /api/expenses/totals e atualiza os cards.

Ollama

Modelo principal deepseek-r1:7b.

Cliente com format:"json", repeat_penalty:1.2, stop:["OBS_TOOL","USER:","ASSISTANT:","TOOL:"].

Docs

README alinhado (Web + FastAPI + DeepSeek + porta 8000).

Anotar que a branch é main (Codex/CI).

3) IMPACT

IA deixa de ser papagaio e executa pedidos.

UI reflete alterações imediatamente.

Quem clonar sobe o projeto em minutos.

4) Mapa do repo (alvo)
/backend
  /ai
    /prompts/xuzinha_base.txt
    /tools/
      ollama_client.py
      db_adapter.py
      web_fetch.py
      intent_router.py
      lang.py
  /config/ai_model.yaml
  app.py
  requirements.txt
/web
  /src/services/agent.ts   # API_BASE, chat, refresh totals
/scripts
  run_backend.bat
  run_web.bat
  dev_all.bat
  smoke.ps1
/docs
  repo_analysis.md

5) Contratos de API
5.1 Chat

POST /api/chat/xuzinha

{ "user_id": "ui", "message": "aumente Food em 20" }

Resposta:

{ "final_answer": "OK. Food +20.", "used_tools": ["db.update_expense"] }

5.2 Totais

GET /api/expenses/totals

{ "source": "api|file", "totals": { "Food": 170.0, "Transport": 45.0 } }

5.3 Health

GET /

{ "ok": true, "service": "xuzinha-core", "tools": ["db.get_expenses", "..."] }

6) Comandos de dev (Windows)
# modelos (uma vez)
ollama pull deepseek-r1:7b
ollama pull llama3:latest
ollama pull phi3:mini

# backend
cd backend
pip install -r requirements.txt
python app.py   # porta 8000

# web
cd web
npm i
npm run dev -- --port 3000

7) Smoke test (curl)
curl http://127.0.0.1:8000/
curl -X POST http://127.0.0.1:8000/api/chat/xuzinha \
  -H "Content-Type: application/json" \
  -d '{"user_id":"smoke","message":"listar despesas por categoria"}'

curl -X POST http://127.0.0.1:8000/api/chat/xuzinha \
  -H "Content-Type: application/json" \
  -d '{"user_id":"smoke","message":"aumente Food em 20"}'

curl http://127.0.0.1:8000/api/expenses/totals


Esperado: used_tools=["db.get_expenses"] no 1º; ["db.update_expense"] no 2º; totais atualizados.

8) Riscos & Mitigações

Loop do LLM → anti-loop + “finalize agora” + repeat_penalty.

Prolixidade → prompt curto + format:"json" + clamp.

UI parada → refetch após db.*.

Portas conflitantes → padrão 8000; remover :5002/:8001.

Branch errada no Codex → usar main.

9) Critérios de Aceite

A1: “listar despesas por categoria” → resposta ≤ 2 frases, used_tools=["db.get_expenses"].

A2: “aumente Food em 20” → used_tools=["db.update_expense"]; GET /api/expenses/totals reflete +20; UI atualiza.

A3: “Set Transport to 100” → responde no mesmo idioma; used_tools=["db.set_category"].

A4: “zerar tudo” → used_tools=["db.reset"]; totais zerados; UI atualiza.

A5: “inflação no Canadá?” → usa web.search/web.fetch; resposta curta com número.

A6: GET / retorna ok:true e lista de tools.

A7: Nenhuma resposta repete a mesma tool >1x.

10) Notas de limpeza (opcional)

Para recomeçar limpo mantendo a URL:

rm -rf .git
git init
git add .
git commit -m "init: fresh clean version"
git branch -M main
git remote add origin https://github.com/marcobarreto007/Xubudget.git
git push -u origin -f main


Pronto. Qualquer desvio, usa o MSAR:
DIVERGENCE / PATH_FIX / IMPACT e a gente realinha o pipeline todo de uma vez.

Réflexion étendue
Connecteurs
Ajouter des sources
ChatGPT peut faire des erreurs. Vérifiez les informations importantes. Reportez-vous à la section Préférences de témoins.
