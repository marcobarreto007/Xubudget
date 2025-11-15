# Setup Completo - Xubudget AI

## ✅ Correções Realizadas

### 1. Dependências Python Corrigidas
- **numpy**: Ajustado para versão compatível com chromadb (`>=1.22.5,<2.0.0`)
- **httpx**: Atualizado para `>=0.28.1` (compatível com ddgs e chromadb)
- **langdetect**: Adicionado `langdetect==1.0.9` (faltava no requirements.txt)
- **requests**: Adicionado explicitamente
- **readability-lxml**: Removido (substituído por solução BeautifulSoup pura)

### 2. Frontend Construído
- Dependências Node.js instaladas
- Build React criado em `xuzinha_dashboard/build/`
- Frontend pronto para ser servido pelo FastAPI

### 3. Backend Funcional
- Todas as importações funcionando
- Servidor FastAPI inicia corretamente
- Endpoints configurados:
  - `GET /` - Health check
  - `POST /api/chat/xuzinha` - Chat com IA
  - `GET /api/expenses/totals` - Totais de despesas
  - `GET /dashboard` - Frontend React

### 4. Scripts Criados
- `scripts/run_all.sh` - Script Linux para iniciar tudo

## 🚀 Como Rodar

### Opção 1: Script Automático (Linux)
```bash
./scripts/run_all.sh
```

### Opção 2: Manual

#### Backend
```bash
cd services/pi2_assistant
python3 -m pip install --user -r requirements.txt
python3 app.py
```
Backend estará em: http://127.0.0.1:8000

#### Frontend (já construído)
O frontend já está construído e será servido automaticamente pelo FastAPI em:
- http://127.0.0.1:8000/dashboard

Se precisar reconstruir:
```bash
cd services/pi2_assistant/xuzinha_dashboard
npm install
npm run build
```

## ⚠️ Observações

1. **Ollama**: O sistema requer Ollama rodando com o modelo `deepseek-r1:7b`
   - Instalar: https://ollama.ai
   - Baixar modelo: `ollama pull deepseek-r1:7b`
   - O backend tentará conectar em `http://127.0.0.1:11434`

2. **Dependências Python**: Instaladas em `~/.local/lib/python3.12/site-packages`
   - Se usar venv, ajuste os comandos conforme necessário

3. **Frontend**: O build está em `services/pi2_assistant/xuzinha_dashboard/build/`
   - FastAPI serve automaticamente os arquivos estáticos

## 📝 Endpoints Disponíveis

- `GET /` - Health check + lista de ferramentas
- `GET /health` - Health check
- `GET /api` - Info da API
- `POST /api/chat/xuzinha` - Chat com a Xuzinha
  ```json
  {
    "user_id": "usuario123",
    "message": "listar despesas por categoria"
  }
  ```
- `GET /api/expenses/totals` - Totais de despesas
- `GET /dashboard` - Interface web React

## ✅ Status

- ✅ Backend: Funcionando
- ✅ Frontend: Construído e pronto
- ✅ Dependências: Todas instaladas
- ⚠️ Ollama: Requer instalação e modelo (não verificado)
