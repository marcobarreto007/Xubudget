"""
Teste simples do fluxo de despesas
"""

import requests
import json
from datetime import datetime

def test_api():
    """Testa a API de despesas"""
    base_url = "http://localhost:5003"
    
    print("Testando Xubudget API...")
    
    # Teste 1: Health check
    try:
        response = requests.get(f"{base_url}/api/health", timeout=5)
        if response.status_code == 200:
            print("✓ API esta rodando")
        else:
            print(f"✗ API retornou status {response.status_code}")
            return
    except Exception as e:
        print(f"✗ Erro ao conectar: {e}")
        return
    
    # Teste 2: Adicionar despesas
    print("\nAdicionando 3 despesas...")
    expenses = [
        {"description": "Almoco no restaurante", "amount": 45.50, "category": "alimentacao"},
        {"description": "Uber para trabalho", "amount": 12.80, "category": "transporte"},
        {"description": "Farmacia - remedios", "amount": 28.90, "category": "saude"}
    ]
    
    added_ids = []
    for i, expense in enumerate(expenses, 1):
        try:
            response = requests.post(f"{base_url}/api/expenses", json=expense, timeout=10)
            if response.status_code == 200:
                result = response.json()
                added_ids.append(result['id'])
                print(f"✓ Despesa {i} adicionada - ID: {result['id']}")
            else:
                print(f"✗ Erro ao adicionar despesa {i}: {response.status_code}")
        except Exception as e:
            print(f"✗ Erro na requisicao {i}: {e}")
    
    # Teste 3: Listar todas
    print(f"\nListando todas as despesas...")
    try:
        response = requests.get(f"{base_url}/api/expenses", timeout=10)
        if response.status_code == 200:
            all_expenses = response.json()
            print(f"✓ Total de despesas: {len(all_expenses)}")
            for exp in all_expenses:
                print(f"  ID {exp['id']}: {exp['description']} - R$ {exp['amount']} ({exp['category']})")
        else:
            print(f"✗ Erro ao listar: {response.status_code}")
    except Exception as e:
        print(f"✗ Erro na requisicao: {e}")
    
    # Teste 4: Agrupar por categoria
    print(f"\nAgrupando por categoria...")
    try:
        response = requests.get(f"{base_url}/api/expenses/by-category", timeout=10)
        if response.status_code == 200:
            expenses = response.json()
            categories = {}
            for exp in expenses:
                cat = exp['category']
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(exp)
            
            print(f"✓ Categorias encontradas: {len(categories)}")
            for cat, exps in categories.items():
                total = sum(e['amount'] for e in exps)
                print(f"  {cat.upper()}: {len(exps)} despesas - Total: R$ {total:.2f}")
        else:
            print(f"✗ Erro ao agrupar: {response.status_code}")
    except Exception as e:
        print(f"✗ Erro na requisicao: {e}")
    
    # Teste 5: Resumo
    print(f"\nGerando resumo...")
    try:
        response = requests.get(f"{base_url}/api/expenses/summary", timeout=10)
        if response.status_code == 200:
            summary = response.json()
            print(f"✓ Resumo gerado:")
            print(f"  Total de despesas: {summary['total_count']}")
            print(f"  Valor total: R$ {summary['total_amount']:.2f}")
        else:
            print(f"✗ Erro no resumo: {response.status_code}")
    except Exception as e:
        print(f"✗ Erro na requisicao: {e}")
    
    # Teste 6: Categorização
    print(f"\nTestando categorizacao...")
    try:
        test_text = "almoco no restaurante 45 reais"
        response = requests.post(f"{base_url}/api/categorize", 
                               json={"text": test_text}, timeout=10)
        if response.status_code == 200:
            result = response.json()
            print(f"✓ '{test_text}' -> {result['category']} (confianca: {result['confidence']:.2f})")
        else:
            print(f"✗ Erro na categorizacao: {response.status_code}")
    except Exception as e:
        print(f"✗ Erro na requisicao: {e}")
    
    print(f"\nResumo final:")
    print(f"✓ Despesas adicionadas: {len(added_ids)}")
    print(f"✓ Sistema funcionando: {'Sim' if len(added_ids) >= 3 else 'Nao'}")

if __name__ == "__main__":
    test_api()
