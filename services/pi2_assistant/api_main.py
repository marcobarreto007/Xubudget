#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import threading
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List, Optional
import asyncio
import logging
import sys

from fastapi import FastAPI, HTTPException, Request, Header
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# Configure logging
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('debug_server.log', mode='w'),
        logging.StreamHandler(sys.stdout)
    ]
)

# Configuração de caminhos
BASE_DIR = Path(__file__).parent
DATA_DIR = BASE_DIR / "data"
CATEGORIES_PATH = DATA_DIR / "categories.json"
STATE_PATH = DATA_DIR / "user_state.json"

# Criar diretórios se não existirem
DATA_DIR.mkdir(exist_ok=True)

# Carregar categorias com tratamento de BOM
def load_categories():
    if CATEGORIES_PATH.exists():
        try:
            content = CATEGORIES_PATH.read_text(encoding='utf-8')
            return json.loads(content)
        except json.JSONDecodeError:
            # Tentar com utf-8-sig para remover BOM
            try:
                content = CATEGORIES_PATH.read_text(encoding='utf-8-sig')
                return json.loads(content)
            except:
                pass
    
    # Categorias padrão se arquivo não existir ou estiver corrompido
    default_categories = [
        {"id": "supermercado", "name": "Supermercado", "icon": "🛒", "budget": 400, "color": "#48bb78"},
        {"id": "transporte", "name": "Transporte", "icon": "🚗", "budget": 200, "color": "#4299e1"},
        {"id": "alimentacao", "name": "Alimentação", "icon": "🍕", "budget": 300, "color": "#ed8936"},
        {"id": "contas", "name": "Contas", "icon": "⚡", "budget": 250, "color": "#805ad5"},
        {"id": "internet", "name": "Internet", "icon": "📶", "budget": 100, "color": "#38b2ac"},
        {"id": "cafe", "name": "Café", "icon": "☕", "budget": 60, "color": "#d69e2e"},
        {"id": "uber", "name": "Uber", "icon": "🚗", "budget": 120, "color": "#319795"},
        {"id": "saude", "name": "Saúde", "icon": "💊", "budget": 200, "color": "#4facfe"},
        {"id": "lazer", "name": "Lazer", "icon": "🎬", "budget": 150, "color": "#f093fb"},
        {"id": "roupas", "name": "Roupas", "icon": "👕", "budget": 100, "color": "#43e97b"},
        {"id": "educacao", "name": "Educação", "icon": "📚", "budget": 100, "color": "#fa709a"},
        {"id": "beleza", "name": "Beleza", "icon": "💄", "budget": 80, "color": "#fee140"}
    ]
    
    # Salvar categorias padrão
    CATEGORIES_PATH.write_text(json.dumps(default_categories, indent=2), encoding='utf-8')
    return default_categories

# Carregar/salvar estado do usuário
def load_user_state():
    if STATE_PATH.exists():
        try:
            content = STATE_PATH.read_text(encoding='utf-8')
            return json.loads(content)
        except:
            pass
    
    # Estado padrão
    default_state = {
        "user_id": "default",
        "current_month": datetime.now().strftime("%Y-%m"),
        "icons": {},
        "total_income": 0,
        "expenses": []
    }
    
    # Inicializar ícones com categorias
    categories = load_categories()
    for cat in categories:
        default_state["icons"][cat["id"]] = {
            "id": cat["id"],
            "name": cat["name"],
            "icon": cat["icon"],
            "budget": cat["budget"],
            "spent": 0,
            "color": cat["color"]
        }
    
    save_user_state(default_state)
    return default_state

def save_user_state(state):
    STATE_PATH.write_text(json.dumps(state, indent=2), encoding='utf-8')

# Modelos Pydantic
class ChatMessage(BaseModel):
    user_id: str
    message: str

class AddExpenseRequest(BaseModel):
    amount: float
    description: str
    category: str

class ChatResponse(BaseModel):
    response: str
    expense_added: bool = False
    income_added: bool = False

# Inicializar FastAPI
app = FastAPI(title="Xubudget API", version="1.0.0")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Estado global
user_state = load_user_state()
state_lock = threading.Lock()

# Função para atualizar estado
def update_state(user_id: str = "default"):
    global user_state
    current_month = datetime.now().strftime("%Y-%m")
    
    with state_lock:
        if user_state.get("current_month") != current_month:
            # Novo mês - resetar gastos
            for icon_id in user_state.get("icons", {}):
                user_state["icons"][icon_id]["spent"] = 0
            user_state["current_month"] = current_month
            user_state["expenses"] = []
            save_user_state(user_state)

# Função para categorizar gastos
def guess_category(description: str) -> str:
    description_lower = description.lower()
    
    # Mapeamento de palavras-chave para categorias
    category_keywords = {
        "supermercado": ["super", "mercado", "costco", "walmart", "carrefour", "pao", "acucar"],
        "transporte": ["onibus", "metro", "gasolina", "combustivel", "taxi", "uber"],
        "alimentacao": ["restaurante", "lanche", "pizza", "hamburguer", "comida", "jantar"],
        "contas": ["luz", "agua", "gas", "telefone", "internet", "conta"],
        "cafe": ["cafe", "coffee", "starbucks", "cafeteria"],
        "saude": ["farmacia", "remedios", "medico", "hospital", "consulta"],
        "lazer": ["cinema", "teatro", "show", "festa", "diversao"],
        "roupas": ["roupa", "camisa", "calca", "sapato", "tenis"],
        "educacao": ["livro", "curso", "escola", "universidade"],
        "beleza": ["cabelo", "salao", "maquiagem", "perfume"]
    }
    
    for category, keywords in category_keywords.items():
        if any(keyword in description_lower for keyword in keywords):
            return category
    
    return "supermercado"  # Categoria padrão

def smart_guess_category(description: str, amount: float = 0) -> str:
    """Categorização inteligente com verificação expandida"""
    desc_lower = description.lower().strip()
    logging.debug(f"smart_guess_category: desc_lower='{desc_lower}'")
    
    # Verificações prioritárias
    coffee_keywords = ["coffee", "cafe", "café", "starbucks", "tim hortons", 
                      "espresso", "cappuccino", "latte", "mocha"]
    
    for keyword in coffee_keywords:
        if keyword in desc_lower:
            return "cafe"
    
    # Fallback para guess_category original
    return guess_category(description)

def process_chat_command(message: str) -> ChatResponse:
    message_lower = message.lower().strip()
    
    # Detectar gastos
    if any(word in message_lower for word in ["spent", "gastei", "comprei", "paguei"]):
        # Extrair valor
        import re
        valor_match = re.search(r'(\d+(?:,\d{2})?(?:\.\d{2})?)', message)
        
        if valor_match:
            valor_str = valor_match.group(1).replace(',', '.')
            try:
                valor = float(valor_str)
                
                # Guess category
                category = smart_guess_category(message)
                logging.debug(f"process_chat_command: category after smart_guess_category = '{category}'")
                
                # Adicionar gasto
                with state_lock:
                    if category in user_state["icons"]:
                        user_state["icons"][category]["spent"] += valor
                        
                        # Adicionar ao histórico
                        expense = {
                            "id": len(user_state.get("expenses", [])) + 1,
                            "amount": valor,
                            "description": message,
                            "category": category,
                            "date": datetime.now().isoformat(),
                            "user_id": "default"
                        }
                        
                        if "expenses" not in user_state:
                            user_state["expenses"] = []
                        user_state["expenses"].append(expense)
                        
                        save_user_state(user_state)
                        
                        category_name = user_state["icons"][category]["name"]
                        logging.debug(f"process_chat_command: category_name before ChatResponse = '{category_name}'")
                        return ChatResponse(
                            response=f"Anotei! Você gastou R$ {valor:.2f} em {category_name}. Seu orçamento está sendo atualizado.",
                            expense_added=True
                        )
                
                return ChatResponse(
                    response=f"Entendi que você gastou R$ {valor:.2f}, mas não consegui identificar a categoria. Você pode ser mais específico?",
                    expense_added=False
                )
                
            except ValueError:
                pass
    
    # Detectar receitas
    elif any(word in message_lower for word in ["recebi", "ganhei", "salario", "renda"]):
        import re
        valor_match = re.search(r'(\d+(?:,\d{2})?(?:\.\d{2})?)', message)
        
        if valor_match:
            valor_str = valor_match.group(1).replace(',', '.')
            try:
                valor = float(valor_str)
                
                with state_lock:
                    user_state["total_income"] += valor
                    save_user_state(user_state)
                
                return ChatResponse(
                    response=f"Que bom! Anotei sua receita de R$ {valor:.2f}. Sua renda total este mês é R$ {user_state['total_income']:.2f}.",
                    income_added=True
                )
                
            except ValueError:
                pass
    
    # Consultas sobre orçamento
    elif any(word in message_lower for word in ["orcamento", "quanto", "gastei", "sobrou"]):
        total_budget = sum(icon["budget"] for icon in user_state["icons"].values())
        total_spent = sum(icon["spent"] for icon in user_state["icons"].values())
        available = total_budget - total_spent
        
        return ChatResponse(
            response=f"Seu orçamento total é R$ {total_budget:.2f}. Você já gastou R$ {total_spent:.2f} e tem R$ {available:.2f} disponíveis este mês.",
            expense_added=False
        )
    
    # Resposta padrão da Xuzinha
    responses = [
        "Oi! Sou a Xuzinha 🦉 Estou aqui para cuidar das suas finanças. Me conte quanto você gastou ou pergunte sobre seu orçamento!",
        "Como posso ajudar com suas finanças hoje? Você pode me dizer gastos assim: 'gastei 50 no supermercado'",
        "Estou aqui para proteger suas finanças! Me conte seus gastos e receitas que eu cuido de tudo.",
        "Olá! Quer saber como está seu orçamento ou registrar algum gasto? Estou aqui para ajudar!"
    ]
    
    import random
    return ChatResponse(response=random.choice(responses))

# ENDPOINTS

@app.post("/api/chat")
async def chat_endpoint(chat_message: ChatMessage, api_key: str = Header(None, alias="X-API-Key")):
    try:
        # Temporarily disable API key validation for debugging
        # if api_key != "your-api-key" and not os.getenv("DISABLE_API_KEY"):
        #     raise HTTPException(status_code=403, detail="Invalid API key")
        logging.debug(f"DEBUG - Recebida mensagem: {chat_message.message}")
        response = process_chat_command(chat_message.message)
        logging.debug(f"DEBUG - Resposta: {response}")
        return response
    except Exception as e:
        return ChatResponse(
            response="Desculpe, houve um erro ao processar sua mensagem. Tente novamente.",
            expense_added=False
        )

@app.post("/api/add_expense")
async def add_expense(expense: AddExpenseRequest):
    try:
        with state_lock:
            if expense.category in user_state["icons"]:
                user_state["icons"][expense.category]["spent"] += expense.amount
                
                # Adicionar ao histórico
                expense_record = {
                    "id": len(user_state.get("expenses", [])) + 1,
                    "amount": expense.amount,
                    "description": expense.description,
                    "category": expense.category,
                    "date": datetime.now().isoformat(),
                    "user_id": "default"
                }
                
                if "expenses" not in user_state:
                    user_state["expenses"] = []
                user_state["expenses"].append(expense_record)
                
                save_user_state(user_state)
                
                return {"success": True, "message": "Gasto adicionado com sucesso"}
            else:
                raise HTTPException(status_code=400, detail="Categoria não encontrada")
                
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.get("/api/expenses")
async def get_expenses(user_id: str = "default", limit: int = 50):
    update_state(user_id)
    expenses = user_state.get("expenses", [])
    return expenses[-limit:] if len(expenses) > limit else expenses

@app.get("/api/categories")
async def get_categories():
    return load_categories()

# Servir arquivos estáticos do Flutter (se existirem)
flutter_build_path = BASE_DIR.parent.parent / "mobile_app" / "build" / "web"
if flutter_build_path.exists():
    app.mount("/", StaticFiles(directory=str(flutter_build_path), html=True), name="flutter")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5002, reload=True)