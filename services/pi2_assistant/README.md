# Xubudget AI — Web + FastAPI + Ollama (DeepSeek)

**Stack:** React (3000) + FastAPI (8000) + Ollama `deepseek-r1:7b`.  
Fluxo antigo (Flutter/Qwen/5005) está obsoleto.

## 🚀 Setup Rápido

```bash
# 1. Modelos (Ollama)
ollama pull deepseek-r1:7b

# 2. Backend
cd services/pi2_assistant
pip install -r requirements.txt
python app.py    # porta 8000

# 3. Frontend
cd xuzinha_dashboard
npm i
npm run dev -- --port 3000
```

## 🎯 Execução Completa

```bash
# Windows - Executa tudo automaticamente
scripts/run_all.bat

# Testes automatizados
scripts/smoke_test.ps1
```

## 💬 Uso

### Chat com a Xuzinha
- **Backend**: `POST /api/chat/xuzinha`
- **Exemplo**: `{"user_id":"ui", "message":"aumente Food em 20"}`
- **Resposta**: `{"final_answer":"OK. db.update_expense executada.", "used_tools":["db.update_expense"]}`

### Buscar Totais
- **Backend**: `GET /api/expenses/totals`
- **Resposta**: `{"totals":{"Food":120.0, "Transport":50.0}}`

### Health Check
- **Backend**: `GET /`
- **Resposta**: `{"ok":true, "service":"xuzinha-core", "tools":["db.get_expenses", "db.update_expense", ...]}`

## 🧠 IA Xuzinha

### Características
- **Respostas curtas**: ≤2 frases, ≤180 caracteres
- **Multi-idioma**: PT/EN/ES com detecção automática
- **Anti-loop**: Máximo 3 passos, sem repetir ferramentas
- **Ações diretas**: Executa comandos de despesas imediatamente

### Comandos Suportados
- `"listar despesas por categoria"` → `db.get_expenses`
- `"aumente Food em 25"` → `db.update_expense`
- `"setar Transport para 100"` → `db.set_category`
- `"zerar tudo"` → `db.reset`

## 🏗️ Arquitetura

```
/
├── services/pi2_assistant/          # Backend FastAPI
│   ├── ai/                          # IA e ferramentas
│   ├── app.py                       # Servidor principal
│   └── requirements.txt
├── xuzinha_dashboard/               # Frontend React
│   ├── src/components/ChatInterface.tsx
│   └── src/services/agent.ts
├── scripts/                         # Scripts de execução
├── docs/                           # Documentação
└── README.md
```

## 🔧 Desenvolvimento

### Backend (FastAPI)
```bash
cd services/pi2_assistant
pip install -r requirements.txt
python app.py
```

### Frontend (React)
```bash
cd xuzinha_dashboard
npm i
npm run dev -- --port 3000
```

### Testes
```bash
# Smoke test completo
scripts/smoke_test.ps1

# Teste manual
curl -X POST http://127.0.0.1:8000/api/chat/xuzinha \
  -H "Content-Type: application/json" \
  -d '{"user_id":"test","message":"listar despesas"}'
```

## 📋 Notas

- **Branch padrão**: `main`
- **Portas**: Backend 8000, Frontend 3000
- **IA**: DeepSeek-R1 7B via Ollama
- **UI**: Atualiza automaticamente após modificações
- **Respostas**: Sempre curtas e diretas

## 🎉 Status

✅ **SISTEMA 100% FUNCIONAL**
- IA executa comandos diretamente
- Interface atualiza em tempo real
- Anti-loop implementado
- Multi-idioma funcionando
- Scripts de execução prontos
- Documentação completa

---

**Criado por Marco Barreto para Xuzinha, seu amor** 💜