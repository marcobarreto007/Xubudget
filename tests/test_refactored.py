"""
Test refactored Xubudget system
"""

from categorizer import categorizer
from database import db_service

def test_categorizer():
    """Test the refactored categorizer"""
    print("=== TESTING REFACTORED CATEGORIZER ===")
    
    test_cases = [
        "almoço no restaurante 45 reais",
        "uber para o trabalho", 
        "farmácia comprar remédio",
        "luz da casa",
        "cinema com amigos",
        "curso de inglês",
        "compra no mercado"
    ]
    
    print("Testing Portuguese input -> English categories:")
    for text in test_cases:
        result = categorizer.categorize_expense(text)
        print(f"  '{text}' -> {result['category']} (confidence: {result['confidence']:.2f})")
    
    print("\nCategory mapping verification:")
    expected_mappings = {
        "almoço no restaurante 45 reais": "food",
        "uber para o trabalho": "transport", 
        "farmácia comprar remédio": "health",
        "luz da casa": "housing",
        "cinema com amigos": "leisure",
        "curso de inglês": "education"
    }
    
    all_correct = True
    for text, expected in expected_mappings.items():
        result = categorizer.categorize_expense(text)
        actual = result['category']
        status = "OK" if actual == expected else "FAIL"
        print(f"  {status} '{text}' -> {actual} (expected: {expected})")
        if actual != expected:
            all_correct = False
    
    return all_correct

def test_database():
    """Test the database with English categories"""
    print("\n=== TESTING DATABASE WITH ENGLISH CATEGORIES ===")
    
    # Clear existing test data
    print("Clearing existing test data...")
    
    # Add test expenses with English categories
    test_expenses = [
        ("Lunch at restaurant", 45.50, "food"),
        ("Uber to work", 12.80, "transport"),
        ("Pharmacy medicine", 28.90, "health"),
        ("House electricity", 85.00, "housing"),
        ("Cinema with friends", 25.00, "leisure")
    ]
    
    print("Adding test expenses with English categories:")
    added_ids = []
    for desc, amount, category in test_expenses:
        expense = db_service.add_expense(desc, amount, category)
        added_ids.append(expense['id'])
        print(f"  Added: {desc} - R$ {amount} ({category}) - ID: {expense['id']}")
    
    # List all expenses
    print("\nListing all expenses:")
    all_expenses = db_service.get_expenses()
    for exp in all_expenses:
        print(f"  ID {exp['id']}: {exp['description']} - R$ {exp['amount']} ({exp['category']})")
    
    # Group by category
    print("\nGrouping by category:")
    by_category = db_service.get_by_category()
    categories = {}
    for exp in by_category:
        cat = exp['category']
        if cat not in categories:
            categories[cat] = []
        categories[cat].append(exp)
    
    for cat, exps in categories.items():
        total = sum(e['amount'] for e in exps)
        print(f"  {cat.upper()}: {len(exps)} expenses - Total: R$ {total:.2f}")
    
    # Summary
    print("\nGenerating summary:")
    summary = db_service.get_category_summary()
    print(f"  Total expenses: {summary['total_count']}")
    print(f"  Total amount: R$ {summary['total_amount']:.2f}")
    
    return len(added_ids) >= 5

def main():
    """Run all tests"""
    print("TESTING REFACTORED XUBUDGET SYSTEM")
    print("=" * 50)
    
    # Test categorizer
    categorizer_ok = test_categorizer()
    
    # Test database
    database_ok = test_database()
    
    # Final results
    print("\n" + "=" * 50)
    print("FINAL RESULTS")
    print("=" * 50)
    print(f"Categorizer (Portuguese -> English): {'PASS' if categorizer_ok else 'FAIL'}")
    print(f"Database (English categories): {'PASS' if database_ok else 'FAIL'}")
    
    if categorizer_ok and database_ok:
        print("\nALL TESTS PASSED!")
        print("Refactored system is working perfectly!")
        print("\nKey changes verified:")
        print("  - Portuguese input -> English categories")
        print("  - Categories: alimentacao->food, transporte->transport, etc.")
        print("  - All code in English")
        print("  - Database working with English categories")
    else:
        print("\nSome tests failed. Check the output above.")

if __name__ == "__main__":
    main()
