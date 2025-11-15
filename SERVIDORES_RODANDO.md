# 🚀 Servidores em Execução

## ✅ Status Atual

### Backend FastAPI - **RODANDO** ✅
- **Porta:** 8000
- **URL:** http://127.0.0.1:8000
- **Status:** Online e funcionando
- **Endpoints disponíveis:**
  - `GET /` - Health check + ferramentas
  - `GET /health` - Health check
  - `GET /api` - Info da API
  - `POST /api/chat/xuzinha` - Chat com IA
  - `GET /api/expenses/totals` - Totais de despesas
  - `GET /dashboard` - Frontend React (build)

### Frontend React (Build) - **SERVIDO PELO FASTAPI** ✅
- **URL:** http://127.0.0.1:8000/dashboard
- **Status:** Servido pelo FastAPI como arquivos estáticos
- **Build:** `xuzinha_dashboard/build/`

### Frontend React (Dev Mode) - **Tentando iniciar**
- **Porta:** 3000 (se iniciar)
- **URL:** http://127.0.0.1:3000 (quando disponível)
- **Status:** Em processo de inicialização

## 📋 Como Acessar

1. **Backend API:**
   ```bash
   curl http://127.0.0.1:8000/
   ```

2. **Frontend Web:**
   - Via FastAPI: http://127.0.0.1:8000/dashboard
   - Via Dev Server (se iniciar): http://127.0.0.1:3000

3. **Testar Chat:**
   ```bash
   curl -X POST http://127.0.0.1:8000/api/chat/xuzinha \
     -H "Content-Type: application/json" \
     -d '{"user_id":"teste","message":"listar despesas"}'
   ```

## 🔍 Verificar Status

```bash
# Verificar portas em uso
ss -tlnp | grep -E ":(8000|3000)"

# Verificar processos
ps aux | grep -E "(python3 app.py|node|react-scripts)"

# Testar backend
curl http://127.0.0.1:8000/health
```

## ⚠️ Notas

- O backend está rodando em background
- O frontend build está sendo servido pelo FastAPI
- Para funcionalidade completa de IA, é necessário Ollama com modelo `deepseek-r1:7b`
