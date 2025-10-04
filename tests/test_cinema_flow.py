"""
Test specific flow: "gastei 50 no cinema"
"""

import requests
import json

def test_cinema_flow():
    """Test the cinema expense flow specifically"""
    
    print("Testing cinema expense flow...")
    print("=" * 50)
    
    # 1. Test categorization
    print("1. Testing cinema categorization...")
    test_text = "gastei 50 no cinema"
    try:
        response = requests.post(
            "http://localhost:5003/api/categorize",
            json={"text": test_text},
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            print(f"   OK - Categorized: {result['category']} (confidence: {result['confidence']:.2f})")
            category = result['category']
        else:
            print(f"   ERROR - {response.text}")
            return
    except Exception as e:
        print(f"   ERROR: {e}")
        return
    
    # 2. Add cinema expense
    print("\n2. Adding cinema expense...")
    expense_data = {
        "description": test_text,
        "amount": 50.0,
        "category": category,
        "date": "2024-10-04"
    }
    try:
        response = requests.post(
            "http://localhost:5003/api/expenses",
            json=expense_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            result = response.json()
            expense_id = result['id']
            print(f"   OK - Cinema expense added with ID: {expense_id}")
        else:
            print(f"   ERROR - {response.text}")
            return
    except Exception as e:
        print(f"   ERROR: {e}")
        return
    
    # 3. Verify cinema expense
    print("\n3. Verifying cinema expense...")
    try:
        response = requests.get("http://localhost:5003/api/expenses", timeout=10)
        if response.status_code == 200:
            expenses = response.json()
            cinema_expenses = [exp for exp in expenses if 'cinema' in exp['description'].lower()]
            print(f"   OK - Found {len(cinema_expenses)} cinema expenses")
            for exp in cinema_expenses:
                print(f"   - {exp['description']}: R$ {exp['amount']} ({exp['category']})")
        else:
            print(f"   ERROR - {response.text}")
    except Exception as e:
        print(f"   ERROR: {e}")
    
    print("\n" + "=" * 50)
    print("Cinema flow test completed!")
    print("\nNow test in frontend:")
    print("1. Go to http://localhost:3000")
    print("2. Open Xuzinha chat")
    print("3. Type: 'gastei 50 no cinema'")
    print("4. Type: 'sim' or 'sim claro'")
    print("5. Check if it adds the expense!")

if __name__ == "__main__":
    test_cinema_flow()
