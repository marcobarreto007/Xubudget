#!/bin/bash
# Script para iniciar o Xubudget AI

echo "🚀 Iniciando Xubudget AI..."

# Verificar se Ollama está rodando
if ! pgrep -x "ollama" > /dev/null; then
    echo "📦 Iniciando Ollama..."
    nohup ollama serve > /tmp/ollama.log 2>&1 &
    sleep 3
else
    echo "✅ Ollama já está rodando"
fi

# Verificar se o modelo está disponível
if ! ollama list | grep -q "deepseek-r1:7b"; then
    echo "⬇️  Baixando modelo deepseek-r1:7b..."
    ollama pull deepseek-r1:7b
else
    echo "✅ Modelo deepseek-r1:7b disponível"
fi

# Iniciar backend FastAPI
cd /workspace/services/pi2_assistant
if ! pgrep -f "python3 app.py" > /dev/null; then
    echo "🔧 Iniciando Backend FastAPI..."
    export PATH="$HOME/.local/bin:$PATH"
    nohup python3 app.py > /tmp/fastapi.log 2>&1 &
    sleep 5
else
    echo "✅ Backend já está rodando"
fi

# Verificar status
echo ""
echo "📊 Status dos serviços:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama: http://localhost:11434"
else
    echo "❌ Ollama: não está respondendo"
fi

if curl -s http://localhost:8000/health > /dev/null 2>&1; then
    echo "✅ Backend: http://localhost:8000"
else
    echo "❌ Backend: não está respondendo"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🌐 Frontend React está construído em:"
echo "   /workspace/services/pi2_assistant/xuzinha_dashboard/build/"
echo ""
echo "📝 Endpoints disponíveis:"
echo "   • GET  http://localhost:8000/ - Health check"
echo "   • POST http://localhost:8000/api/chat/xuzinha - Chat com IA"
echo "   • GET  http://localhost:8000/api/expenses/totals - Totais de despesas"
echo ""
echo "🎉 Sistema pronto para uso!"
