# XUBUDGET AI - Sistema Financeiro Inteligente

Sistema de gestão financeira com IA que executa comandos e atualiza a interface em tempo real.

## 🚀 Stack Tecnológica

- **Frontend**: React (porta 8000)
- **Backend**: FastAPI (porta 8000) 
- **IA**: Ollama + DeepSeek-R1 7B
- **Banco**: JSON local + API REST

## ⚡ Início Rápido

### 1. Pré-requisitos
```bash
# Instalar Ollama
# Baixar de: https://ollama.ai

# Instalar Python 3.8+
# Instalar Node.js 16+
```

### 2. Configuração Inicial
```bash
# Baixar modelos de IA
ollama pull deepseek-r1:7b
ollama pull llama3:latest
ollama pull phi3:mini
```

### 3. Executar Sistema
```bash
# Windows - Execução completa
scripts\run_all.bat

# Ou manualmente:
# Backend
python app.py

# Frontend (já integrado no backend)
# Acesse: http://127.0.0.1:8000
```

## 🎯 Funcionalidades

### IA Inteligente (Xuzinha)
- **Execução direta**: Comandos como "aumente Food em 20" são executados imediatamente
- **Multi-idioma**: Responde em português, inglês ou espanhol
- **Anti-loop**: Máximo 3 passos, sem repetir ferramentas
- **Respostas curtas**: Máximo 2 frases, 200 caracteres

### Comandos Suportados
```
"listar despesas por categoria"     → db.get_expenses
"aumente Food em 20"                → db.update_expense  
"setar Transport para 100"          → db.set_category
"zerar tudo"                        → db.reset
"7777" ou "todos os números"        → db.set_category (Food=7777)
```

### Interface Web
- Dashboard em tempo real
- Chat com IA integrado
- Atualização automática após comandos
- Design responsivo e moderno

## 🔧 API Endpoints

### Chat com IA
```http
POST /api/chat/xuzinha
Content-Type: application/json

{
  "user_id": "ui",
  "message": "aumente Food em 20"
}
```

**Resposta:**
```json
{
  "final_answer": "OK. Food +20.",
  "used_tools": ["db.update_expense"]
}
```

### Totais de Despesas
```http
GET /api/expenses/totals
```

**Resposta:**
```json
{
  "source": "file",
  "totals": {
    "Food": 170.0,
    "Transport": 45.0
  }
}
```

### Health Check
```http
GET /
```

**Resposta:**
```json
{
  "ok": true,
  "service": "xuzinha-core",
  "tools": ["db.get_expenses", "db.update_expense", "db.set_category", "db.reset"]
}
```

## 🧪 Testes

### Smoke Test Automático
```bash
# Windows
powershell -ExecutionPolicy Bypass -File scripts\smoke_test.ps1

# Manual
curl http://127.0.0.1:8000/
curl -X POST http://127.0.0.1:8000/api/chat/xuzinha -H "Content-Type: application/json" -d '{"user_id":"test","message":"listar despesas"}'
```

### Critérios de Aceite
- ✅ "listar despesas" → `used_tools=["db.get_expenses"]`
- ✅ "aumente Food em 20" → `used_tools=["db.update_expense"]` + UI atualiza
- ✅ "setar Transport para 100" → `used_tools=["db.set_category"]`
- ✅ "zerar tudo" → `used_tools=["db.reset"]` + totais zerados
- ✅ Respostas ≤ 2 frases, ≤ 200 caracteres
- ✅ Sem repetição de ferramentas

## 📁 Estrutura do Projeto

```
xubudget/
├── app.py                          # Backend FastAPI
├── config/
│   └── ai_model.yaml              # Configuração da IA
├── ai/
│   ├── prompts/
│   │   └── xuzinha_base.txt       # Prompt da Xuzinha
│   └── tools/
│       ├── ollama_client.py       # Cliente Ollama
│       ├── db_adapter.py          # Adaptador de dados
│       ├── intent_router.py       # Roteador de intenções
│       └── lang.py                # Detecção de idioma
├── xuzinha_dashboard/             # Frontend React
│   ├── src/
│   │   ├── components/
│   │   │   └── ChatInterface.tsx  # Interface de chat
│   │   └── services/
│   │       └── agent.ts           # Serviço de comunicação
│   └── build/                     # Build do frontend
└── scripts/
    ├── run_all.bat               # Script de execução
    └── smoke_test.ps1            # Testes automatizados
```

## 🔧 Desenvolvimento

### Backend
```bash
cd xubudget
pip install -r requirements.txt
python app.py
```

### Frontend (desenvolvimento)
```bash
cd xuzinha_dashboard
npm install
npm run build
```

### Configuração da IA
Edite `config/ai_model.yaml`:
```yaml
model: deepseek-r1:7b
temperature: 0.7
max_tokens: 200
policy:
  max_steps: 5
  max_same_tool: 2
  response: { max_sentences: 2, max_chars: 200 }
```

## 🐛 Troubleshooting

### Problemas Comuns

1. **Porta 8000 ocupada**
   ```bash
   taskkill /F /IM python.exe
   ```

2. **Ollama não responde**
   ```bash
   ollama serve
   ollama pull deepseek-r1:7b
   ```

3. **Frontend não atualiza**
   - Verifique se `used_tools` contém `db.*`
   - Confirme se `/api/expenses/totals` retorna dados

4. **IA não executa comandos**
   - Verifique se o intent router detecta o comando
   - Confirme se as ferramentas db.* estão funcionando

## 📝 Changelog

### v2.0.0 - Sistema Completo
- ✅ IA executa comandos diretamente
- ✅ Interface atualiza em tempo real  
- ✅ Anti-loop e respostas curtas
- ✅ Multi-idioma (PT/EN/ES)
- ✅ Smoke tests automatizados
- ✅ Documentação completa

### v1.0.0 - MVP
- Interface básica
- Chat com IA
- Gestão de despesas

## 🤝 Contribuição

1. Fork o projeto
2. Crie uma branch (`git checkout -b feature/nova-funcionalidade`)
3. Commit suas mudanças (`git commit -m 'Adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/nova-funcionalidade`)
5. Abra um Pull Request

## 📄 Licença

Este projeto está sob a licença MIT. Veja o arquivo `LICENSE` para mais detalhes.

## 👨‍💻 Autor

**Marco Barreto** - *Desenvolvido para Xuzinha, seu amor* 💜

---

**XUBUDGET AI** - Sistema financeiro inteligente que realmente funciona! 🚀
