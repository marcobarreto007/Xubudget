"""
Script de teste para o fluxo completo de despesas
"""

import requests
import json
import time
from datetime import datetime, timedelta

def test_api_connection():
    """Testa se a API está rodando"""
    try:
        response = requests.get("http://localhost:5003/api/health", timeout=5)
        if response.status_code == 200:
            print("API esta rodando!")
            return True
        else:
            print(f"API retornou status {response.status_code}")
            return False
    except Exception as e:
        print(f"Erro ao conectar com API: {e}")
        return False

def add_test_expenses():
    """Adiciona 3 despesas de teste"""
    test_expenses = [
        {
            "description": "Almoço no restaurante ABC",
            "amount": 45.50,
            "category": "alimentacao",
            "date": datetime.now().strftime("%Y-%m-%d")
        },
        {
            "description": "Uber para o trabalho",
            "amount": 12.80,
            "category": "transporte",
            "date": datetime.now().strftime("%Y-%m-%d")
        },
        {
            "description": "Farmácia - remédios",
            "amount": 28.90,
            "category": "saude",
            "date": (datetime.now() - timedelta(days=1)).strftime("%Y-%m-%d")
        }
    ]
    
    added_expenses = []
    
    for i, expense in enumerate(test_expenses, 1):
        try:
            print(f"\n📝 Adicionando despesa {i}: {expense['description']}")
            response = requests.post(
                "http://localhost:5003/api/expenses",
                json=expense,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                added_expenses.append(result)
                print(f"✅ Despesa adicionada - ID: {result['id']}")
                print(f"   Valor: R$ {result['amount']}")
                print(f"   Categoria: {result['category']}")
            else:
                print(f"❌ Erro ao adicionar despesa: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"❌ Erro na requisição: {e}")
    
    return added_expenses

def list_all_expenses():
    """Lista todas as despesas"""
    try:
        print("\n📋 Listando todas as despesas:")
        response = requests.get("http://localhost:5003/api/expenses", timeout=10)
        
        if response.status_code == 200:
            expenses = response.json()
            print(f"✅ Total de despesas: {len(expenses)}")
            
            for expense in expenses:
                print(f"   ID {expense['id']}: {expense['description']} - R$ {expense['amount']} ({expense['category']}) - {expense['date']}")
            
            return expenses
        else:
            print(f"❌ Erro ao listar despesas: {response.status_code} - {response.text}")
            return []
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return []

def group_by_category():
    """Agrupa despesas por categoria"""
    try:
        print("\n📊 Agrupando despesas por categoria:")
        response = requests.get("http://localhost:5003/api/expenses/by-category", timeout=10)
        
        if response.status_code == 200:
            expenses = response.json()
            
            # Agrupar por categoria
            categories = {}
            for expense in expenses:
                cat = expense['category']
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(expense)
            
            print(f"✅ Despesas agrupadas por {len(categories)} categorias:")
            
            for category, cat_expenses in categories.items():
                total = sum(exp['amount'] for exp in cat_expenses)
                print(f"   {category.upper()}: {len(cat_expenses)} despesas - Total: R$ {total:.2f}")
                for exp in cat_expenses:
                    print(f"     - {exp['description']}: R$ {exp['amount']}")
            
            return categories
        else:
            print(f"❌ Erro ao agrupar despesas: {response.status_code} - {response.text}")
            return {}
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return {}

def get_summary():
    """Obtém resumo das despesas"""
    try:
        print("\n📈 Resumo das despesas:")
        response = requests.get("http://localhost:5003/api/expenses/summary", timeout=10)
        
        if response.status_code == 200:
            summary = response.json()
            print(f"✅ Resumo gerado:")
            print(f"   Total de despesas: {summary['total_count']}")
            print(f"   Valor total: R$ {summary['total_amount']:.2f}")
            
            if summary['recent_expense']:
                recent = summary['recent_expense']
                print(f"   Despesa mais recente: {recent['description']} - R$ {recent['amount']} ({recent['date']})")
            
            print(f"\n   Detalhes por categoria:")
            for cat in summary['categories']:
                print(f"     {cat['category'].upper()}: {cat['count']} despesas - R$ {cat['total']:.2f} (média: R$ {cat['average']:.2f})")
            
            return summary
        else:
            print(f"❌ Erro ao obter resumo: {response.status_code} - {response.text}")
            return None
            
    except Exception as e:
        print(f"❌ Erro na requisição: {e}")
        return None

def test_categorization():
    """Testa categorização automática"""
    try:
        print("\n🤖 Testando categorização automática:")
        test_texts = [
            "almoço no restaurante 45 reais",
            "uber para o trabalho",
            "farmácia comprar remédio"
        ]
        
        for text in test_texts:
            response = requests.post(
                "http://localhost:5003/api/categorize",
                json={"text": text},
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            if response.status_code == 200:
                result = response.json()
                print(f"   '{text}' -> {result['category']} (confiança: {result['confidence']:.2f})")
            else:
                print(f"   ❌ Erro ao categorizar '{text}': {response.status_code}")
                
    except Exception as e:
        print(f"❌ Erro na categorização: {e}")

if __name__ == "__main__":
    print("Testando fluxo completo do Xubudget API...")
    
    # Teste 1: Conectividade
    if not test_api_connection():
        print("❌ API não está rodando. Inicie com: python main.py")
        exit(1)
    
    # Teste 2: Adicionar despesas
    print("\n" + "="*50)
    print("TESTE 1: Adicionando 3 despesas")
    print("="*50)
    added_expenses = add_test_expenses()
    
    # Teste 3: Listar todas
    print("\n" + "="*50)
    print("TESTE 2: Listando todas as despesas")
    print("="*50)
    all_expenses = list_all_expenses()
    
    # Teste 4: Agrupar por categoria
    print("\n" + "="*50)
    print("TESTE 3: Agrupando por categoria")
    print("="*50)
    categories = group_by_category()
    
    # Teste 5: Resumo
    print("\n" + "="*50)
    print("TESTE 4: Resumo das despesas")
    print("="*50)
    summary = get_summary()
    
    # Teste 6: Categorização
    print("\n" + "="*50)
    print("TESTE 5: Categorização automática")
    print("="*50)
    test_categorization()
    
    # Resumo final
    print("\n" + "="*50)
    print("RESUMO FINAL")
    print("="*50)
    print(f"✅ Despesas adicionadas: {len(added_expenses)}")
    print(f"✅ Total de despesas no banco: {len(all_expenses)}")
    print(f"✅ Categorias encontradas: {len(categories)}")
    print(f"✅ Resumo gerado: {'Sim' if summary else 'Não'}")
    
    if len(added_expenses) >= 3 and len(all_expenses) >= 3:
        print("\n🎉 TODOS OS TESTES PASSARAM!")
        print("O sistema de persistência está funcionando perfeitamente!")
    else:
        print("\n⚠️ Alguns testes falharam. Verifique os logs acima.")
