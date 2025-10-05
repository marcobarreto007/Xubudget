# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\language_detector.py
# REM (WHY): detectar idioma automaticamente para responder na mesma língua

import re
from typing import Dict, List

# Palavras-chave para detectar idiomas
LANGUAGE_PATTERNS = {
    "portuguese": [
        "oi", "olá", "bom dia", "boa tarde", "boa noite", "obrigado", "obrigada",
        "por favor", "desculpe", "desculpa", "sim", "não", "talvez", "claro",
        "entendi", "compreendi", "perfeito", "ótimo", "excelente", "legal",
        "gastei", "gastou", "comprei", "comprou", "dinheiro", "orçamento",
        "quanto", "quando", "onde", "como", "por que", "para que", "qual",
        "quero", "preciso", "posso", "devo", "vou", "estou", "sou", "tenho",
        "fiz", "fez", "vou fazer", "vai fazer", "pode", "consegue", "ajuda",
        "ajudar", "me ajuda", "pode ajudar", "consegue ajudar", "obrigado",
        "valeu", "brigado", "vlw", "tmj", "beleza", "tranquilo", "suave"
    ],
    "english": [
        "hi", "hello", "good morning", "good afternoon", "good evening", "thanks", "thank you",
        "please", "sorry", "excuse me", "yes", "no", "maybe", "sure", "okay", "ok",
        "understood", "got it", "perfect", "great", "excellent", "awesome", "cool",
        "spent", "spend", "bought", "buy", "money", "budget", "finance", "financial",
        "how much", "when", "where", "how", "why", "what", "which", "who",
        "want", "need", "can", "should", "will", "am", "is", "are", "have", "has",
        "did", "do", "does", "will do", "can you", "help", "help me", "please help",
        "thanks", "thank you", "thx", "ty", "np", "no problem", "sure thing"
    ],
    "spanish": [
        "hola", "buenos días", "buenas tardes", "buenas noches", "gracias", "por favor",
        "perdón", "disculpe", "sí", "no", "tal vez", "claro", "entendido", "perfecto",
        "excelente", "genial", "gasté", "gastó", "compré", "compró", "dinero", "presupuesto",
        "cuánto", "cuándo", "dónde", "cómo", "por qué", "para qué", "cuál", "quién",
        "quiero", "necesito", "puedo", "debo", "voy", "estoy", "soy", "tengo", "hice",
        "hizo", "voy a hacer", "va a hacer", "puede", "puedes", "ayuda", "ayudar",
        "me ayuda", "puede ayudar", "gracias", "vale", "ok", "perfecto", "genial",
        "como", "estas", "estás", "como estas", "como estás", "que tal", "qué tal",
        "bien", "mal", "regular", "muy bien", "muy mal", "todo bien", "todo mal"
    ],
    "french": [
        "salut", "bonjour", "bonsoir", "merci", "s'il vous plaît", "pardon", "excusez-moi",
        "oui", "non", "peut-être", "bien sûr", "compris", "parfait", "excellent", "génial",
        "j'ai dépensé", "a dépensé", "j'ai acheté", "a acheté", "argent", "budget",
        "combien", "quand", "où", "comment", "pourquoi", "pour quoi", "quel", "qui",
        "je veux", "j'ai besoin", "je peux", "je dois", "je vais", "je suis", "j'ai",
        "j'ai fait", "a fait", "je vais faire", "va faire", "peut", "peux", "aide",
        "aider", "peux m'aider", "peut aider", "merci", "ok", "parfait", "génial"
    ]
}

def detect_language(text: str) -> str:
    """
    Detecta o idioma do texto baseado em palavras-chave comuns.
    Retorna o código do idioma ou 'portuguese' como padrão.
    """
    if not text or not isinstance(text, str):
        return "portuguese"
    
    text_lower = text.lower().strip()
    
    # Remove pontuação e caracteres especiais
    text_clean = re.sub(r'[^\w\s]', ' ', text_lower)
    words = text_clean.split()
    
    if not words:
        return "portuguese"
    
    # Conta ocorrências de cada idioma
    language_scores = {}
    
    for lang, patterns in LANGUAGE_PATTERNS.items():
        score = 0
        for word in words:
            if word in patterns:
                score += 1
        language_scores[lang] = score
    
    # Retorna o idioma com maior pontuação
    if language_scores:
        detected_lang = max(language_scores, key=language_scores.get)
        if language_scores[detected_lang] > 0:
            return detected_lang
    
    # Se não detectou nada, verifica caracteres especiais
    if any(char in text for char in "ñ"):
        return "spanish"
    elif any(char in text for char in "çãõáéíóúâêôàèìòù"):
        return "portuguese"
    elif any(char in text for char in "àâäéèêëïîôöùûüÿç"):
        return "french"
    
    # Padrão: português
    return "portuguese"

def get_language_instructions(language: str) -> str:
    """
    Retorna instruções específicas para cada idioma.
    """
    instructions = {
        "portuguese": "Responda SEMPRE em português do Brasil. Use tom familiar e direto.",
        "english": "Respond ALWAYS in English. Use a friendly and direct tone.",
        "spanish": "Responde SIEMPRE en español. Usa un tono familiar y directo.",
        "french": "Réponds TOUJOURS en français. Utilise un ton familier et direct."
    }
    
    return instructions.get(language, instructions["portuguese"])

def get_language_greeting(language: str) -> str:
    """
    Retorna saudação específica para cada idioma.
    """
    greetings = {
        "portuguese": "Eu sou a Xuzinha 💜, o amor do Xuzinho! Como posso ajudar com suas finanças?",
        "english": "I'm Xuzinha 💜, Xuzinho's love! How can I help you with your finances?",
        "spanish": "¡Soy Xuzinha 💜, el amor de Xuzinho! ¿Cómo puedo ayudarte con tus finanzas?",
        "french": "Je suis Xuzinha 💜, l'amour de Xuzinho ! Comment puis-je t'aider avec tes finances ?"
    }
    
    return greetings.get(language, greetings["portuguese"])
