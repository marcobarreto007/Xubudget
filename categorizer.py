"""
Xubudget Categorizer Service
Categorizes Brazilian expenses using Ollama API
"""

import requests
import json
from typing import Dict, Optional
import logging

logger = logging.getLogger(__name__)

class CategorizerService:
    def __init__(self, ollama_url: str = "http://localhost:11434", model: str = "qwen2.5:7b-instruct"):
        self.ollama_url = ollama_url
        self.model = model
        self.timeout = 10
    
    def categorize_expense(self, text: str) -> Dict[str, any]:
        """
        Categorizes a Brazilian expense using Ollama API
        
        Args:
            text (str): Expense text to categorize
            
        Returns:
            Dict[str, any]: {"category": str, "confidence": float}
        """
        try:
            # Optimized prompt for categorization (Portuguese for Brazilian expense recognition)
            prompt = f"""Categorize esta despesa brasileira em uma das seguintes categorias: alimentacao, transporte, saude, moradia, lazer, educacao, outros. 

Responda apenas com a categoria, sem explicações.

Texto: {text}

Categoria:"""

            # Prepare request for Ollama
            payload = {
                "model": self.model,
                "prompt": prompt,
                "stream": False,
                "options": {
                    "temperature": 0.1,
                    "top_p": 0.9,
                    "max_tokens": 50
                }
            }

            # Make request to Ollama
            response = requests.post(
                f"{self.ollama_url}/api/generate",
                json=payload,
                timeout=self.timeout
            )

            if response.status_code == 200:
                result = response.json()
                ai_response = result.get("response", "").strip().lower()
                
                # Map response to valid category
                category = self._map_response_to_category(ai_response)
                confidence = self._calculate_confidence(ai_response, text)
                
                logger.info(f"Successful categorization: '{text}' -> '{category}' (confidence: {confidence})")
                
                return {
                    "category": category,
                    "confidence": confidence
                }
            else:
                logger.error(f"Ollama API error: {response.status_code} - {response.text}")
                return self._fallback_categorization(text)
                
        except requests.exceptions.Timeout:
            logger.error("Timeout in Ollama request")
            return self._fallback_categorization(text)
        except requests.exceptions.ConnectionError:
            logger.error("Connection error with Ollama")
            return self._fallback_categorization(text)
        except Exception as e:
            logger.error(f"Unexpected error in categorization: {e}")
            return self._fallback_categorization(text)
    
    def _map_response_to_category(self, response: str) -> str:
        """Maps AI response to a valid category"""
        response = response.strip().lower()
        
        # Mapping of possible responses to categories
        category_mapping = {
            'food': ['alimentacao', 'alimentação', 'comida', 'restaurante', 'mercado', 'supermercado', 'padaria'],
            'transport': ['transporte', 'uber', 'taxi', 'combustivel', 'gasolina', 'onibus', 'metro'],
            'health': ['saude', 'saúde', 'farmacia', 'farmácia', 'hospital', 'medico', 'médico', 'clinica'],
            'housing': ['moradia', 'casa', 'aluguel', 'luz', 'agua', 'água', 'internet', 'energia'],
            'leisure': ['lazer', 'cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel', 'entretenimento'],
            'education': ['educacao', 'educação', 'escola', 'universidade', 'curso', 'livro', 'estudo'],
            'other': ['outros', 'outro', 'diversos', 'miscelanea', 'miscelânea']
        }
        
        # Find corresponding category
        for category, keywords in category_mapping.items():
            if any(keyword in response for keyword in keywords):
                return category
        
        # If not found, return 'other'
        return 'other'
    
    def _calculate_confidence(self, ai_response: str, original_text: str) -> float:
        """Calculates confidence based on AI response"""
        # If response contains exactly one valid category
        valid_categories = ['food', 'transport', 'health', 'housing', 'leisure', 'education', 'other']
        
        if ai_response in valid_categories:
            return 0.95
        elif any(cat in ai_response for cat in valid_categories):
            return 0.85
        else:
            return 0.70
    
    def _fallback_categorization(self, text: str) -> Dict[str, any]:
        """Fallback categorization using keywords"""
        text_lower = text.lower()
        
        # Keywords for each category
        keywords = {
            'food': ['restaurante', 'mercado', 'super', 'padaria', 'lanche', 'comida', 'cafe', 'pizza', 'delivery', 'almoço', 'jantar'],
            'transport': ['uber', 'taxi', 'posto', 'combustivel', 'gasolina', 'onibus', 'metro', 'estacionamento', 'gas'],
            'health': ['farmacia', 'hospital', 'medico', 'clinica', 'consulta', 'exame', 'medicina', 'drogaria'],
            'housing': ['casa', 'aluguel', 'condominio', 'luz', 'agua', 'gas', 'internet', 'telefone', 'energia'],
            'leisure': ['cinema', 'teatro', 'bar', 'festa', 'viagem', 'hotel', 'entretenimento', 'jogo', 'spotify', 'netflix'],
            'education': ['escola', 'universidade', 'curso', 'livro', 'material', 'estudo', 'faculdade']
        }
        
        # Find category with most keywords
        category_scores = {}
        for category, words in keywords.items():
            score = sum(1 for word in words if word in text_lower)
            if score > 0:
                category_scores[category] = score
        
        if category_scores:
            best_category = max(category_scores, key=category_scores.get)
            confidence = min(0.8, 0.5 + (category_scores[best_category] * 0.1))
            return {"category": best_category, "confidence": confidence}
        
        return {"category": "other", "confidence": 0.5}

# Global service instance
categorizer = CategorizerService()