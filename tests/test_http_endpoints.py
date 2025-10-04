#!/usr/bin/env python3
"""
Test HTTP endpoints for Xubudget API
Tests all API endpoints using requests
"""

import requests
import json
import time
import sys

# API Configuration
API_BASE_URL = "http://localhost:5003"
ENDPOINTS = {
    "health": f"{API_BASE_URL}/api/health",
    "categorize": f"{API_BASE_URL}/api/categorize", 
    "add_expense": f"{API_BASE_URL}/api/expenses",
    "get_expenses": f"{API_BASE_URL}/api/expenses",
    "get_by_category": f"{API_BASE_URL}/api/expenses/by-category",
    "get_summary": f"{API_BASE_URL}/api/expenses/summary",
    "ollama_status": f"{API_BASE_URL}/api/ollama-status"
}

def test_server_connection():
    """Test if server is running"""
    print("=== TESTING SERVER CONNECTION ===")
    try:
        response = requests.get(ENDPOINTS["health"], timeout=5)
        if response.status_code == 200:
            print("OK Server is running and responding")
            return True
        else:
            print(f"ERROR Server returned status {response.status_code}")
            return False
    except requests.exceptions.ConnectionError:
        print("ERROR Cannot connect to server. Is it running on port 5003?")
        return False
    except Exception as e:
        print(f"ERROR Unexpected error: {e}")
        return False

def test_health_endpoint():
    """Test health check endpoint"""
    print("\n=== TESTING HEALTH ENDPOINT ===")
    try:
        response = requests.get(ENDPOINTS["health"])
        if response.status_code == 200:
            data = response.json()
            print(f"OK Health check: {data}")
            return True
        else:
            print(f"ERROR Health check failed: {response.status_code}")
            return False
    except Exception as e:
        print(f"ERROR Health check error: {e}")
        return False

def test_categorize_endpoint():
    """Test categorization endpoint"""
    print("\n=== TESTING CATEGORIZE ENDPOINT ===")
    
    test_cases = [
        "almoço no restaurante 45 reais",
        "uber para o trabalho",
        "farmácia comprar remédio"
    ]
    
    success_count = 0
    for text in test_cases:
        try:
            payload = {"text": text}
            response = requests.post(ENDPOINTS["categorize"], json=payload)
            
            if response.status_code == 200:
                data = response.json()
                print(f"OK '{text}' -> {data['category']} (confidence: {data['confidence']:.2f})")
                success_count += 1
            else:
                print(f"ERROR Categorization failed for '{text}': {response.status_code}")
                
        except Exception as e:
            print(f"ERROR Categorization error for '{text}': {e}")
    
    print(f"OK Categorization: {success_count}/{len(test_cases)} successful")
    return success_count == len(test_cases)

def test_add_expense_endpoint():
    """Test add expense endpoint"""
    print("\n=== TESTING ADD EXPENSE ENDPOINT ===")
    
    test_expenses = [
        {
            "description": "HTTP_TEST_Lunch at restaurant",
            "amount": 45.50,
            "category": "food",
            "date": "2025-01-15"
        },
        {
            "description": "HTTP_TEST_Uber to work",
            "amount": 12.80,
            "category": "transport", 
            "date": "2025-01-15"
        },
        {
            "description": "HTTP_TEST_Pharmacy medicine",
            "amount": 28.90,
            "category": "health",
            "date": "2025-01-14"
        }
    ]
    
    added_expenses = []
    success_count = 0
    
    for expense in test_expenses:
        try:
            response = requests.post(ENDPOINTS["add_expense"], json=expense)
            
            if response.status_code == 200:
                data = response.json()
                added_expenses.append(data)
                print(f"OK Added: {data['description']} - R$ {data['amount']} ({data['category']}) - ID: {data['id']}")
                success_count += 1
            else:
                print(f"ERROR Add expense failed: {response.status_code} - {response.text}")
                
        except Exception as e:
            print(f"ERROR Add expense error: {e}")
    
    print(f"OK Add expenses: {success_count}/{len(test_expenses)} successful")
    return added_expenses

def test_get_expenses_endpoint():
    """Test get expenses endpoint"""
    print("\n=== TESTING GET EXPENSES ENDPOINT ===")
    
    try:
        # Test without parameters
        response = requests.get(ENDPOINTS["get_expenses"])
        if response.status_code == 200:
            data = response.json()
            print(f"OK Retrieved {len(data)} expenses")
            
            # Show first few expenses
            for exp in data[:3]:
                print(f"  - ID {exp['id']}: {exp['description']} - R$ {exp['amount']} ({exp['category']})")
            
            if len(data) > 3:
                print(f"  ... and {len(data) - 3} more")
        else:
            print(f"ERROR Get expenses failed: {response.status_code}")
            return False
            
        # Test with days parameter
        response = requests.get(f"{ENDPOINTS['get_expenses']}?days=30")
        if response.status_code == 200:
            data = response.json()
            print(f"OK Retrieved {len(data)} expenses from last 30 days")
        else:
            print(f"ERROR Get expenses with days parameter failed: {response.status_code}")
            
        return True
        
    except Exception as e:
        print(f"ERROR Get expenses error: {e}")
        return False

def test_get_by_category_endpoint():
    """Test get expenses by category endpoint"""
    print("\n=== TESTING GET BY CATEGORY ENDPOINT ===")
    
    try:
        # Test without category filter
        response = requests.get(ENDPOINTS["get_by_category"])
        if response.status_code == 200:
            data = response.json()
            print(f"OK Retrieved {len(data)} expenses by category")
            
            # Group by category
            categories = {}
            for exp in data:
                cat = exp['category']
                if cat not in categories:
                    categories[cat] = []
                categories[cat].append(exp)
            
            print("  Categories breakdown:")
            for cat, exps in categories.items():
                total = sum(e['amount'] for e in exps)
                print(f"    {cat.upper()}: {len(exps)} expenses - Total: R$ {total:.2f}")
        else:
            print(f"ERROR Get by category failed: {response.status_code}")
            return False
            
        # Test with specific category
        response = requests.get(f"{ENDPOINTS['get_by_category']}?category=food")
        if response.status_code == 200:
            data = response.json()
            print(f"OK Retrieved {len(data)} food expenses")
        else:
            print(f"ERROR Get by specific category failed: {response.status_code}")
            
        return True
        
    except Exception as e:
        print(f"ERROR Get by category error: {e}")
        return False

def test_get_summary_endpoint():
    """Test get summary endpoint"""
    print("\n=== TESTING GET SUMMARY ENDPOINT ===")
    
    try:
        response = requests.get(ENDPOINTS["get_summary"])
        if response.status_code == 200:
            data = response.json()
            print(f"OK Summary generated:")
            print(f"  Total expenses: {data['total_count']}")
            print(f"  Total amount: R$ {data['total_amount']:.2f}")
            
            if data['recent_expense']:
                recent = data['recent_expense']
                print(f"  Most recent: {recent['description']} - R$ {recent['amount']} ({recent['date']})")
            
            print("  Categories breakdown:")
            for cat_info in data['categories']:
                print(f"    {cat_info['category']}: {cat_info['count']} items, R$ {cat_info['total']:.2f} (avg: R$ {cat_info['average']:.2f})")
            
            return True
        else:
            print(f"ERROR Get summary failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"ERROR Get summary error: {e}")
        return False

def test_ollama_status_endpoint():
    """Test Ollama status endpoint"""
    print("\n=== TESTING OLLAMA STATUS ENDPOINT ===")
    
    try:
        response = requests.get(ENDPOINTS["ollama_status"])
        if response.status_code == 200:
            data = response.json()
            print(f"OK Ollama status: {data['status']}")
            if 'models' in data:
                print(f"  Available models: {len(data['models'])}")
            return True
        else:
            print(f"ERROR Ollama status failed: {response.status_code}")
            return False
            
    except Exception as e:
        print(f"ERROR Ollama status error: {e}")
        return False

def main():
    """Main test function"""
    print("XUBUDGET API - HTTP ENDPOINTS TEST")
    print("=" * 50)
    
    # Check if server is running
    if not test_server_connection():
        print("\nCRITICAL ERROR: Server is not running!")
        print("Please start the server with: python main.py")
        return False
    
    # Run all tests
    tests = [
        ("Health Check", test_health_endpoint),
        ("Categorize", test_categorize_endpoint),
        ("Add Expenses", test_add_expense_endpoint),
        ("Get Expenses", test_get_expenses_endpoint),
        ("Get by Category", test_get_by_category_endpoint),
        ("Get Summary", test_get_summary_endpoint),
        ("Ollama Status", test_ollama_status_endpoint)
    ]
    
    passed = 0
    total = len(tests)
    
    for test_name, test_func in tests:
        try:
            if test_func():
                passed += 1
        except Exception as e:
            print(f"ERROR {test_name} failed with exception: {e}")
    
    # Final results
    print("\n" + "=" * 50)
    print("HTTP ENDPOINTS TEST RESULTS")
    print("=" * 50)
    print(f"Passed: {passed}/{total} tests")
    
    if passed == total:
        print("OK All HTTP endpoints are working correctly!")
        print("The Xubudget API is ready for production!")
    else:
        print(f"ERROR {total - passed} tests failed. Check the output above.")
    
    return passed == total

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)
