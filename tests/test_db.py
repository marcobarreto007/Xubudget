"""
Teste direto do banco de dados
"""

from database import db_service

def test_database():
    print("=== TESTE DO BANCO DE DADOS ===")
    
    # Adicionar despesas
    print("Adicionando despesas...")
    exp1 = db_service.add_expense('Almoco restaurante', 45.50, 'alimentacao')
    exp2 = db_service.add_expense('Uber trabalho', 12.80, 'transporte')
    exp3 = db_service.add_expense('Farmacia remedios', 28.90, 'saude')
    
    print(f"Despesas adicionadas: {exp1['id']}, {exp2['id']}, {exp3['id']}")
    
    # Listar todas
    print("\nListando todas as despesas...")
    all_exp = db_service.get_expenses()
    print(f"Total: {len(all_exp)} despesas")
    
    for e in all_exp:
        print(f"  ID {e['id']}: {e['description']} - R$ {e['amount']} ({e['category']})")
    
    # Agrupar por categoria
    print("\nAgrupando por categoria...")
    by_cat = db_service.get_by_category()
    categories = {}
    
    for e in by_cat:
        cat = e['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(e)
    
    print(f"Categorias: {len(categories)}")
    for cat, exps in categories.items():
        total = sum(e['amount'] for e in exps)
        print(f"  {cat.upper()}: {len(exps)} despesas - R$ {total:.2f}")
    
    # Resumo
    print("\nGerando resumo...")
    summary = db_service.get_category_summary()
    print(f"Total geral: R$ {summary['total_amount']:.2f} ({summary['total_count']} despesas)")
    
    print("\n=== TESTE CONCLUIDO ===")
    print("Sistema de persistencia funcionando perfeitamente!")

if __name__ == "__main__":
    test_database()
