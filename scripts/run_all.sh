#!/bin/bash
# Script para rodar backend e frontend no Linux
set -e

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT/services/pi2_assistant"

# Backend
echo "[INFO] Iniciando backend na porta 8000..."
python3 app.py &
BACKEND_PID=$!
echo "[INFO] Backend iniciado (PID: $BACKEND_PID)"

# Aguardar backend iniciar
sleep 3

# Frontend (se build existir, servir via FastAPI, senão iniciar dev server)
if [ -d "xuzinha_dashboard/build" ]; then
    echo "[INFO] Frontend build encontrado, servindo via FastAPI"
    echo "[OK] Backend http://127.0.0.1:8000  |  Web http://127.0.0.1:8000/dashboard"
else
    echo "[WARN] Build não encontrado. Execute: cd xuzinha_dashboard && npm run build"
    echo "[OK] Backend http://127.0.0.1:8000"
fi

wait $BACKEND_PID
