# Xubudget — Repo Analysis (MSAR)

**Branch padrão:** `main`.  
**Stack:** React (3000) + FastAPI (8000) + Ollama `deepseek-r1:7b`.  
**Objetivo:** IA age (db.*), respostas curtas, UI atualiza.

## DIVERGENCE
- README/scripts antigos (Flutter/Qwen/5005) ≠ runtime (Web + 8000 + DeepSeek).
- Front não refazia fetch após ações → "cego".
- Agente ruminava → faltava anti-loop + finalização JSON.
- Codex usou `master` (inexistente) em vez de `main`.

## PATH_FIX
- Backend 8000, orquestrador anti-loop, roteador de intenção (db.*), JSON estrito.
- Front chama `/api/chat/xuzinha`; se used_tools contém db.*, faz refetch de `/api/expenses/totals`.
- Ollama com `format:"json"`, `repeat_penalty:1.2`, `stop` para cortar papagaio.
- README corrigido e docs aqui.

## IMPACT
- IA executa pedidos sem enrolar.
- UI reflete mudanças na hora.
- Onboarding em minutos.

## REPO MAP
```
/
├── services/pi2_assistant/          # Backend FastAPI
│   ├── ai/
│   │   ├── prompts/xuzinha_base.txt # Prompt da IA
│   │   ├── tools/                   # Ferramentas da IA
│   │   └── config/ai_model.yaml     # Configuração
│   ├── app.py                       # Servidor principal
│   └── requirements.txt
├── xuzinha_dashboard/               # Frontend React
│   ├── src/
│   │   ├── components/ChatInterface.tsx
│   │   └── services/agent.ts
│   └── package.json
├── scripts/                         # Scripts de execução
│   ├── run_all.bat
│   └── smoke_test.ps1
├── docs/                           # Documentação
│   └── repo_analysis.md
└── README.md
```

## CONTRATOS API
- **POST** `/api/chat/xuzinha` → `{"final_answer":"...", "used_tools":["..."]}`
- **GET** `/api/expenses/totals` → `{"totals":{...}}`
- **GET** `/` → `{"ok":true, "service":"xuzinha-core", "tools":[...]}`

## DEV COMMANDS
```bash
# Modelos (Ollama)
ollama pull deepseek-r1:7b

# Backend
cd services/pi2_assistant
pip install -r requirements.txt
python app.py    # porta 8000

# Frontend
cd xuzinha_dashboard
npm i
npm run dev -- --port 3000

# Execução completa
scripts/run_all.bat

# Testes
scripts/smoke_test.ps1
```

## SMOKE TESTS
1. **Health Check**: `GET /` → service: "xuzinha-core"
2. **Listar Despesas**: "listar despesas por categoria" → `used_tools: ["db.get_expenses"]`
3. **Aumentar Despesa**: "aumente Food em 25" → `used_tools: ["db.update_expense"]`
4. **Definir Categoria**: "setar Transport para 100" → `used_tools: ["db.set_category"]`
5. **Buscar Totais**: `GET /api/expenses/totals` → `totals: {...}`
6. **Zerar Tudo**: "zerar tudo" → `used_tools: ["db.reset"]`

## RISKS & MITIGATIONS
- **Risco**: IA entra em loop infinito
- **Mitigação**: `max_steps: 3`, `max_same_tool: 1`, `repeat_penalty: 1.2`

- **Risco**: Frontend não atualiza após mudanças
- **Mitigação**: Refetch automático quando `used_tools` contém `db.*`

- **Risco**: Respostas muito longas
- **Mitigação**: `max_chars: 180`, `max_sentences: 2`

## ACCEPTANCE CRITERIA
- [x] IA executa comandos de despesas diretamente
- [x] Respostas curtas (≤2 frases, ≤180 chars)
- [x] UI atualiza automaticamente após modificações
- [x] Anti-loop funciona (máx 3 passos, sem repetir tool)
- [x] Multi-idioma (PT/EN/ES) com detecção automática
- [x] Scripts de execução funcionais
- [x] Documentação completa
- [x] Smoke tests automatizados

## STATUS
✅ **IMPLEMENTADO E FUNCIONAL**
- Backend FastAPI rodando na porta 8000
- Frontend React rodando na porta 3000
- IA Xuzinha com ferramentas db.* funcionando
- Sistema anti-loop implementado
- UI atualizando em tempo real
- Documentação completa
- Scripts de execução prontos
