# WHY: FastAPI backend server for AI expense categorization using Ollama with fallback regex
import os
import re
from typing import Optional
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import requests
from dotenv import load_dotenv
import json

load_dotenv()

app = FastAPI(title="Xubudget AI Categorizer", version="1.0.0")

# Configuration
OLLAMA_URL = os.getenv("OLLAMA_URL", "http://127.0.0.1:11434")
MODEL_NAME = os.getenv("MODEL_NAME", "qwen2.5:1.5b-instruct")
REQUEST_TIMEOUT = int(os.getenv("REQUEST_TIMEOUT", "5"))

class CategorizeRequest(BaseModel):
    text: str

class CategorizeResponse(BaseModel):
    category: str
    confidence: float
    method: str  # "ai" or "regex"
    description: Optional[str] = None
    amount: Optional[float] = None
    date: Optional[str] = None

@app.get("/healthz")
async def health_check():
    """Health check endpoint"""
    return {"status": "healthy", "service": "xubudget-categorizer"}

@app.post("/categorize", response_model=CategorizeResponse)
async def categorize_expense(request: CategorizeRequest):
    """Categorize expense using AI with regex fallback"""
    
    # Try AI categorization first
    try:
        ai_result = await _categorize_with_ai(request.text)
        if ai_result:
            return ai_result
    except Exception as e:
        print(f"AI categorization failed: {e}")
    
    # Fallback to regex categorization
    return _categorize_with_regex(request.text)

async def _categorize_with_ai(text: str) -> Optional[CategorizeResponse]:
    """Attempt categorization using Ollama"""
    try:
        prompt = f"""Analise o seguinte texto de despesa e categorize-o. Responda apenas com um JSON v+ílido no formato:
{{"category": "categoria", "confidence": 0.95, "description": "descri+º+úo", "amount": 0.0}}

Categorias v+ílidas: alimentacao, transporte, saude, moradia, lazer, educacao, outros

Texto: {text}

JSON:"""

        ollama_request = {
            "model": MODEL_NAME,
            "prompt": prompt,
            "stream": False,
            "options": {
                "temperature": 0.1,
                "num_predict": 100
            }
        }

        response = requests.post(
            f"{OLLAMA_URL}/api/generate",
            json=ollama_request,
            timeout=REQUEST_TIMEOUT
        )

        if response.status_code == 200:
            result = response.json()
            ai_response = result.get("response", "").strip()
            
            # Try to extract JSON from AI response
            try:
                # Find JSON in the response
                json_match = re.search(r'\{.*\}', ai_response, re.DOTALL)
                if json_match:
                    ai_data = json.loads(json_match.group())
                    return CategorizeResponse(
                        category=ai_data.get("category", "outros"),
                        confidence=float(ai_data.get("confidence", 0.8)),
                        method="ai",
                        description=ai_data.get("description"),
                        amount=ai_data.get("amount")
                    )
            except (json.JSONDecodeError, ValueError):
                pass

    except Exception as e:
        print(f"Ollama request failed: {e}")
    
    return None

def _categorize_with_regex(text: str) -> CategorizeResponse:
    """Fallback categorization using regex patterns"""
    text_lower = text.lower()
    
    # Category keywords mapping
    categories = {
        'alimentacao': ['market', 'mercado', 'super', 'padaria', 'restaurante', 'lanche', 'comida', 'food', 'cafe', 'pizza', 'delivery'],
        'transporte': ['uber', 'taxi', 'posto', 'combustivel', 'gasolina', 'onibus', 'metro', 'gas', 'fuel', 'estacionamento'],
        'saude': ['farmacia', 'hospital', 'medico', 'clinica', 'consulta', 'exame', 'medicina', 'pharmacy', 'drogaria'],
        'moradia': ['casa', 'aluguel', 'condominio', 'luz', 'agua', 'gas', 'internet', 'telefone', 'energia'],
        'lazer': ['cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel', 'entretenimento', 'jogo', 'spotify', 'netflix'],
        'educacao': ['escola', 'universidade', 'curso', 'livro', 'material', 'estudo', 'faculdade'],
    }
    
    # Find matching category
    for category, keywords in categories.items():
        for keyword in keywords:
            if keyword in text_lower:
                return CategorizeResponse(
                    category=category,
                    confidence=0.7,
                    method="regex"
                )
    
    return CategorizeResponse(
        category="outros",
        confidence=0.5,
        method="regex"
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5001)
