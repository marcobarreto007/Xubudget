# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\voice_processor.py
# REM (WHY): processar comandos de voz e extrair informações financeiras

import re
from typing import Dict, List, Optional

def process_voice_command(voice_text: str) -> Dict[str, any]:
    """
    Processa comando de voz e extrai informações financeiras.
    Retorna dados estruturados para adicionar gastos.
    """
    voice_text = voice_text.lower().strip()
    
    # Padrões para extrair valores
    value_patterns = [
        r'(\d+(?:\.\d{2})?)\s*(?:dólares?|dollars?|reais?|cad)',
        r'(\d+(?:\.\d{2})?)\s*(?:reais?|dólares?|dollars?)',
        r'gastei?\s*(\d+(?:\.\d{2})?)',
        r'comprei?\s*por\s*(\d+(?:\.\d{2})?)',
        r'paguei?\s*(\d+(?:\.\d{2})?)',
        r'(\d+(?:\.\d{2})?)\s*em',
        r'(\d+(?:\.\d{2})?)\s*para'
    ]
    
    # Padrões para extrair categorias
    category_patterns = {
        'alimentação': ['comida', 'restaurante', 'lanche', 'jantar', 'almoço', 'café', 'pizza', 'hambúrguer'],
        'supermercado': ['supermercado', 'mercado', 'compras', 'grocery', 'shopping'],
        'transporte': ['uber', 'taxi', 'gasolina', 'ônibus', 'metrô', 'transporte', 'viagem'],
        'saúde': ['médico', 'farmácia', 'hospital', 'clínica', 'medicamento', 'saúde'],
        'entretenimento': ['cinema', 'filme', 'jogo', 'netflix', 'spotify', 'diversão'],
        'roupas': ['roupa', 'camisa', 'calça', 'sapato', 'loja', 'shopping'],
        'utilidades': ['luz', 'água', 'internet', 'telefone', 'conta', 'energia']
    }
    
    # Padrões para extrair lojas/merchants
    merchant_patterns = [
        r'na\s+([a-záêôãç\s]+)',
        r'no\s+([a-záêôãç\s]+)',
        r'da\s+([a-záêôãç\s]+)',
        r'do\s+([a-záêôãç\s]+)',
        r'em\s+([a-záêôãç\s]+)',
        r'@\s*([a-záêôãç\s]+)'
    ]
    
    # Extrair valor
    amount = None
    for pattern in value_patterns:
        match = re.search(pattern, voice_text)
        if match:
            amount = float(match.group(1))
            break
    
    # Extrair categoria
    category = 'outros'
    for cat, keywords in category_patterns.items():
        if any(keyword in voice_text for keyword in keywords):
            category = cat
            break
    
    # Extrair merchant
    merchant = 'Desconhecido'
    for pattern in merchant_patterns:
        match = re.search(pattern, voice_text)
        if match:
            merchant = match.group(1).strip().title()
            break
    
    # Extrair descrição
    description = voice_text
    
    return {
        'amount': amount,
        'category': category,
        'merchant': merchant,
        'description': description,
        'source': 'voice',
        'confidence': 0.8 if amount else 0.3
    }

def validate_voice_command(processed_data: Dict[str, any]) -> Dict[str, any]:
    """
    Valida dados processados do comando de voz.
    """
    if not processed_data['amount']:
        return {
            'valid': False,
            'error': 'Não consegui identificar o valor do gasto. Tente falar "gastei 50 reais no supermercado".',
            'suggestion': 'Fale o valor claramente, como "gastei 25 dólares" ou "comprei por 15 reais".'
        }
    
    if processed_data['amount'] > 10000:
        return {
            'valid': False,
            'error': 'Valor muito alto detectado. Confirme se está correto.',
            'suggestion': 'Se o valor estiver correto, confirme digitando "sim" ou "confirmar".'
        }
    
    return {
        'valid': True,
        'data': processed_data,
        'message': f"Detectei: ${processed_data['amount']} em {processed_data['category']} na {processed_data['merchant']}. Confirma?"
    }
