Xubudget — Repo Analysis (MSAR)

Branch correta: main (⚠️ não existe master).
Stack alvo: React (3000) + FastAPI (8000) + Ollama deepseek-r1:7b.
Meta: IA age (db.*) + responde curta + UI atualiza.

1) DIVERGENCE

README e scripts antigos falam Flutter / Qwen / porta 5005.

Runtime atual é Web/React + FastAPI 8000 + DeepSeek (Ollama).

Front ainda não refresca após db.update_expense → parece “cego”.

Agente às vezes rumina (loops / textão) → falta anti-loop + finalização.

Codex falhou com Provided git ref master does not exist → branch é main.

2) PATH_FIX (mínimo que resolve)

Backend (8000)

Orquestrador com anti-loop (max 3 passos / no-repeat).

Roteador de intenção (PT/EN/ES) → db.get_expenses, db.update_expense, db.set_category, db.reset.

JSON estrito (final_answer, used_tools), respostas ≤ 2 frases.

Endpoints extra: GET /api/expenses/totals e GET / (health).

Front

API_BASE = http://127.0.0.1:8000.

Chat usa /api/chat/xuzinha.

Se used_tools conter db.update_expense|db.set_category|db.reset → refetch GET /api/expenses/totals e atualiza cards.

Ollama

Modelo deepseek-r1:7b (mais llama3, phi3 opcionais).

Cliente forçando format:"json", repeat_penalty:1.2, stop: ["OBS_TOOL","USER:","ASSISTANT:","TOOL:"].

Docs

README alinhado (Web + FastAPI + DeepSeek + porta 8000).

Observação: branch main.

3) IMPACT

IA para de ser papagaio e executa pedidos de despesas.

UI muda na hora após ajustes.

Onboarding limpa: quem clona sobe em minutos.

4) Mapa do repositório (alvo)
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
  repo_analysis.md         # este arquivo

5) Contratos (API)
5.1 Chat

POST /api/chat/xuzinha

{ "user_id": "ui", "message": "aumente Food em 20" }

Resposta:

{ "final_answer": "OK. Food +20.", "used_tools": ["db.update_expense"] }

5.2 Totais

GET /api/expenses/totals →

{ "source": "api|file", "totals": { "Food": 170.0, "Transport": 45.0 } }

5.3 Health

GET / →

{ "ok": true, "service": "xuzinha-core", "tools": ["db.get_expenses", "..."] }

6) Comandos de dev (Windows)
# modelos (uma vez)
ollama pull deepseek-r1:7b
ollama pull llama3:latest
ollama pull phi3:mini

# backend
cd backend
pip install -r requirements.txt
python app.py   # roda na 8000

# web
cd web
npm i
npm run dev -- --port 3000

7) Check rápido (curl)
curl http://127.0.0.1:8000/
curl -X POST http://127.0.0.1:8000/api/chat/xuzinha ^
  -H "Content-Type: application/json" ^
  -d "{\"user_id\":\"smoke\",\"message\":\"listar despesas por categoria\"}"

curl -X POST http://127.0.0.1:8000/api/chat/xuzinha ^
  -H "Content-Type: application/json" ^
  -d "{\"user_id\":\"smoke\",\"message\":\"aumente Food em 20\"}"

curl http://127.0.0.1:8000/api/expenses/totals


Esperado: used_tools=["db.get_expenses"] no primeiro; ["db.update_expense"] no segundo; e totais atualizados.

8) Riscos & Mitigações

Loop no LLM → anti-loop (máx. 1 repetição) + “finalize agora” + repeat_penalty.

Modelo prolixo → prompt curto + format:"json" + clamp (≤ 2 frases/180 chars).

Front não atualiza → hook de refetch após db.*.

Múltiplas portas → padronizar 8000; remover 5002/8001 do front/scripts.

Branch inválida → usar main no Codex/CI.

9) Tarefas para o Codex (ordem única)

Criar/atualizar arquivos do backend listados na seção Mapa com o conteúdo especificado no patch “Codex Task — Xubudget” (já preparado).

Ajustar front: criar web/src/services/agent.ts; integrar no Chat; substituir base URLs para http://127.0.0.1:8000.

Adicionar scripts em /scripts e README.md novo (Web + FastAPI + DeepSeek).

Garantir requirements.txt com langdetect, readability-lxml, bs4, httpx, etc.

Commit:

feat(core): agente anti-loop + db.* + i18n + json estrito

feat(front): service agent + refresh de totais

chore(scripts): dev_all + smoke

docs: README atualizado; docs/repo_analysis.md

10) Critérios de Aceite (objetivos, sem subjetivo)

A1: “listar despesas por categoria” → resposta ≤ 2 frases, used_tools=["db.get_expenses"].

A2: “aumente Food em 20” → used_tools=["db.update_expense"]; GET /api/expenses/totals retorna Food com +20; UI reflete em até 1s após resposta.

A3: Mudança de idioma (“Set Transport to 100”) → resposta no mesmo idioma; used_tools=["db.set_category"].

A4: “zerar tudo” → used_tools=["db.reset"]; totais zerados; UI atualiza.

A5: “inflação no Canadá?” → usa web.search/web.fetch; resposta curta com número atual.

A6: GET / retorna ok: true e lista de tools.

A7: Nenhuma chamada repete a mesma ferramenta mais de 1x (anti-loop).

A8: Front não tem referências a :5002/:8001.

11) Observações finais

Se quiser idioma fixo sempre PT-BR, basta setar flag XU_FORCE_LANG=pt no backend (não implementado por padrão).

Se o DeepSeek ainda “falar demais”, reduzir max_tokens para 120 e aumentar repeat_penalty para 1.3.

Pronto. Este arquivo é a referência do repo.
Qualquer divergência, manda o MSAR (DIVERGENCE / PATH_FIX / IMPACT) que a gente realinha de uma vez.

Réflexion étendue
Connecteurs
Ajouter des sources
ChatGPT pode fazer des erreurs. Vérifiez les informations importantes. Reportez-vous à la section Préférences de témoins.
