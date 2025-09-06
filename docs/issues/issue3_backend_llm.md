# [Backend] Categorizer com LLM local (Ollama + Qwen2.5-1.5B) + client Dart

**Objetivo**
Trocar heurística por LLM leve e local via Ollama, com fallback por regex. Atualizar client Dart.

**Arquivos**
1) services/pi2_assistant/requirements.txt  (+requests)
2) services/pi2_assistant/pi2_server.py     (POST /categorize usa Ollama http://127.0.0.1:11434 com model "qwen2.5:1.5b-instruct"; fallback regex; GET /healthz)
3) mobile_app/lib/services/categorizer_service.dart (client http p/ chamar /categorize)

**Regras**
- `WHY:` no topo dos 3 arquivos.
- Não baixar modelo no repositório; documentar no PR como instalar Ollama e executar `ollama pull qwen2.5:1.5b-instruct`.
- Timeout baixo e temperatura baixa (0.1). Se o LLM não responder, usar fallback regex.
- Apenas os arquivos listados.

**Pronto quando**
- `uvicorn ...:5001` responde `/healthz`.
- POST `/categorize` retorna categoria coerente para 3 exemplos do PR (alimentacao/transporte/saude).
