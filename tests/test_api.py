"""
Script de teste para a API Xubudget
"""

import requests
import json
import time

def test_ollama():
    """Testa se Ollama está rodando"""
    try:
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code == 200:
            models = response.json().get("models", [])
            print("Ollama esta rodando!")
            print(f"Modelos disponiveis: {[m['name'] for m in models]}")
            return True
        else:
            print(f"Ollama retornou status {response.status_code}")
            return False
    except Exception as e:
        print(f"Erro ao conectar com Ollama: {e}")
        return False

def test_categorizer():
    """Testa o categorizador diretamente"""
    try:
        from categorizer import categorizer
        
        test_cases = [
            "almoço no restaurante 45 reais",
            "uber para o trabalho",
            "farmácia comprar remédio",
            "luz da casa",
            "cinema com amigos"
        ]
        
        print("\nTestando categorizador diretamente:")
        for text in test_cases:
            result = categorizer.categorize_expense(text)
            print(f"'{text}' -> {result['category']} (confianca: {result['confidence']:.2f})")
        
        return True
    except Exception as e:
        print(f"Erro no categorizador: {e}")
        return False

def test_api_server():
    """Testa se a API está rodando"""
    try:
        # Testar health endpoint
        response = requests.get("http://localhost:5003/api/health", timeout=5)
        if response.status_code == 200:
            print("API esta rodando!")
            print(f"Health response: {response.json()}")
            return True
        else:
            print(f"API retornou status {response.status_code}")
            return False
    except Exception as e:
        print(f"Erro ao conectar com API: {e}")
        return False

def test_categorize_endpoint():
    """Testa o endpoint de categorização"""
    try:
        test_data = {
            "text": "almoço no restaurante 45 reais"
        }
        
        response = requests.post(
            "http://localhost:5003/api/categorize",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        if response.status_code == 200:
            result = response.json()
            print("Categorizacao via API funcionando!")
            print(f"Resultado: {result}")
            return True
        else:
            print(f"API retornou status {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"Erro na categorizacao via API: {e}")
        return False

if __name__ == "__main__":
    print("Testando Xubudget API...")
    
    # Teste 1: Ollama
    ollama_ok = test_ollama()
    
    # Teste 2: Categorizador direto
    categorizer_ok = test_categorizer()
    
    # Teste 3: API Server
    api_ok = test_api_server()
    
    # Teste 4: Endpoint de categorização
    if api_ok:
        categorize_ok = test_categorize_endpoint()
    else:
        categorize_ok = False
    
    print("\nResumo dos testes:")
    print(f"Ollama: {'OK' if ollama_ok else 'FALHOU'}")
    print(f"Categorizador: {'OK' if categorizer_ok else 'FALHOU'}")
    print(f"API Server: {'OK' if api_ok else 'FALHOU'}")
    print(f"Categorizacao API: {'OK' if categorize_ok else 'FALHOU'}")
    
    if all([ollama_ok, categorizer_ok, api_ok, categorize_ok]):
        print("\nTodos os testes passaram!")
    else:
        print("\nAlguns testes falharam. Verifique os logs acima.")
