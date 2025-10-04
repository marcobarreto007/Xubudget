"""
Test complete flow: Categorize -> Add Expense -> Verify
"""

import requests
import json
import time

def test_complete_flow():
    """Test the complete flow from categorization to adding expense"""
    
    print("Testing complete Xubudget flow...")
    print("=" * 50)
    
    # 1. Test health
    print("1. Testing API health...")
    try:
        response = requests.get("http://localhost:5003/api/health", timeout=5)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            print("   OK - API is healthy")
        else:
            print("   ERROR - API is not healthy")
            return
    except Exception as e:
        print(f"   ERROR Error: {e}")
        return
    
    # 2. Test categorization
    print("\n2. Testing expense categorization...")
    test_text = "eu gastei 120 no restaurante"
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
            print(f"   OK Categorized: {result['category']} (confidence: {result['confidence']:.2f})")
            category = result['category']
        else:
            print(f"   ERROR Error: {response.text}")
            return
    except Exception as e:
        print(f"   ERROR Error: {e}")
        return
    
    # 3. Add expense
    print("\n3. Adding expense to database...")
    expense_data = {
        "description": test_text,
        "amount": 120.0,
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
            print(f"   OK Expense added with ID: {expense_id}")
        else:
            print(f"   ERROR Error: {response.text}")
            return
    except Exception as e:
        print(f"   ERROR Error: {e}")
        return
    
    # 4. Verify expense was added
    print("\n4. Verifying expense in database...")
    try:
        response = requests.get("http://localhost:5003/api/expenses", timeout=10)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            expenses = response.json()
            print(f"   OK Found {len(expenses)} expenses in database")
            
            # Find our expense
            our_expense = next((exp for exp in expenses if exp['id'] == expense_id), None)
            if our_expense:
                print(f"   OK Our expense found: {our_expense['description']} - R$ {our_expense['amount']}")
            else:
                print("   ERROR Our expense not found")
        else:
            print(f"   ERROR Error: {response.text}")
    except Exception as e:
        print(f"   ERROR Error: {e}")
    
    # 5. Test summary
    print("\n5. Testing summary...")
    try:
        response = requests.get("http://localhost:5003/api/expenses/summary", timeout=10)
        print(f"   Status: {response.status_code}")
        if response.status_code == 200:
            summary = response.json()
            print(f"   OK Summary generated: {summary['total_amount']} total")
        else:
            print(f"   ERROR Error: {response.text}")
    except Exception as e:
        print(f"   ERROR Error: {e}")
    
    print("\n" + "=" * 50)
    print("Complete flow test finished!")
    print("\nNow test in the frontend:")
    print("1. Go to http://localhost:3000")
    print("2. Open Xuzinha chat")
    print("3. Type: 'eu gastei 120 no restaurante'")
    print("4. Confirm adding the expense")
    print("5. Check if the dashboard updates!")

if __name__ == "__main__":
    test_complete_flow()