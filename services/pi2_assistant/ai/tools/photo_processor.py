# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\photo_processor.py
# REM (WHY): processar fotos de recibos e extrair informações financeiras

import re
from typing import Dict, List, Optional
import base64

def process_receipt_photo(photo_data: str) -> Dict[str, any]:
    """
    Processa foto de recibo e extrai informações financeiras.
    Simula OCR básico com padrões de texto.
    """
    # Simula texto extraído do OCR
    # Em produção, usaria Tesseract ou API de OCR
    
    # Padrões para extrair valores
    value_patterns = [
        r'total[:\s]*\$?(\d+\.\d{2})',
        r'amount[:\s]*\$?(\d+\.\d{2})',
        r'subtotal[:\s]*\$?(\d+\.\d{2})',
        r'(\d+\.\d{2})\s*total',
        r'(\d+\.\d{2})\s*amount'
    ]
    
    # Padrões para extrair data
    date_patterns = [
        r'(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{2,4})',
        r'(\d{1,2})\s+de\s+(\w+)\s+de\s+(\d{4})',
        r'(\d{4})[\/\-](\d{1,2})[\/\-](\d{1,2})'
    ]
    
    # Padrões para extrair merchant
    merchant_patterns = [
        r'^([A-Z][A-Za-z\s&]+)$',  # Linha toda em maiúscula
        r'([A-Z][A-Za-z\s&]+)\s*receipt',
        r'([A-Z][A-Za-z\s&]+)\s*store'
    ]
    
    # Simula texto extraído (em produção viria do OCR)
    simulated_text = """
    WALMART SUPERSTORE
    123 Main Street
    Toronto, ON M1A 1A1
    
    Receipt #123456789
    Date: 10/05/2025
    
    Items:
    - Bread $2.50
    - Milk $3.99
    - Eggs $4.25
    - Apples $5.75
    
    Subtotal: $16.49
    Tax: $2.15
    Total: $18.64
    
    Thank you for shopping!
    """
    
    # Extrair valor total
    amount = None
    for pattern in value_patterns:
        match = re.search(pattern, simulated_text, re.IGNORECASE)
        if match:
            amount = float(match.group(1))
            break
    
    # Extrair data
    date = None
    for pattern in date_patterns:
        match = re.search(pattern, simulated_text)
        if match:
            if len(match.groups()) == 3:
                if len(match.group(3)) == 4:  # YYYY-MM-DD
                    date = f"{match.group(3)}-{match.group(2).zfill(2)}-{match.group(1).zfill(2)}"
                else:  # DD/MM/YYYY
                    date = f"{match.group(3)}-{match.group(2).zfill(2)}-{match.group(1).zfill(2)}"
            break
    
    # Extrair merchant
    merchant = 'Desconhecido'
    for pattern in merchant_patterns:
        match = re.search(pattern, simulated_text, re.MULTILINE)
        if match:
            merchant = match.group(1).strip()
            break
    
    # Determinar categoria baseada no merchant
    category = 'supermercado'
    if any(word in merchant.lower() for word in ['walmart', 'superstore', 'grocery', 'market']):
        category = 'supermercado'
    elif any(word in merchant.lower() for word in ['restaurant', 'cafe', 'pizza', 'burger']):
        category = 'alimentação'
    elif any(word in merchant.lower() for word in ['gas', 'fuel', 'station']):
        category = 'transporte'
    elif any(word in merchant.lower() for word in ['pharmacy', 'drug', 'medical']):
        category = 'saúde'
    
    return {
        'amount': amount,
        'category': category,
        'merchant': merchant,
        'date': date or '2025-10-05',
        'description': f'Recibo {merchant}',
        'source': 'photo',
        'confidence': 0.9 if amount else 0.3,
        'items': ['Bread', 'Milk', 'Eggs', 'Apples']  # Simulado
    }

def validate_receipt_data(processed_data: Dict[str, any]) -> Dict[str, any]:
    """
    Valida dados processados do recibo.
    """
    if not processed_data['amount']:
        return {
            'valid': False,
            'error': 'Não consegui identificar o valor no recibo. Tente uma foto mais clara.',
            'suggestion': 'Certifique-se de que o total está visível e legível na foto.'
        }
    
    if processed_data['amount'] > 5000:
        return {
            'valid': False,
            'error': 'Valor muito alto detectado no recibo. Confirme se está correto.',
            'suggestion': 'Se o valor estiver correto, confirme digitando "sim" ou "confirmar".'
        }
    
    return {
        'valid': True,
        'data': processed_data,
        'message': f"Recibo processado: ${processed_data['amount']} em {processed_data['category']} na {processed_data['merchant']}. Confirma?"
    }
