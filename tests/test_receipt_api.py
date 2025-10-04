"""
Test script for receipt scanning API
"""

import requests
import json

def test_receipt_scanning():
    """Test the receipt scanning functionality"""
    
    # Sample receipt text
    sample_receipt = """
    WALMART SUPERCENTER
    123 Main Street
    Toronto, ON M1A 1A1
    
    Receipt #12345
    Date: 2024-10-04
    Cashier: John Doe
    
    Items:
    - Milk 2L          $4.99
    - Bread Whole Wheat $2.49
    - Apples 2lbs      $3.99
    - Chicken Breast   $12.99
    
    Subtotal:         $24.46
    Tax (13%):        $3.18
    Total:            $27.64
    
    Thank you for shopping!
    """
    
    # Test data
    test_data = {
        "text": sample_receipt
    }
    
    try:
        print("Testing receipt scanning API...")
        print("=" * 50)
        
        # Test health endpoint first
        print("1. Testing health endpoint...")
        health_response = requests.get("http://localhost:5003/api/health", timeout=5)
        print(f"   Status: {health_response.status_code}")
        if health_response.status_code == 200:
            print(f"   Response: {health_response.json()}")
        else:
            print(f"   Error: {health_response.text}")
            return
        
        # Test receipt scanning
        print("\n2. Testing receipt scanning...")
        scan_response = requests.post(
            "http://localhost:5003/api/scan-receipt",
            json=test_data,
            headers={"Content-Type": "application/json"},
            timeout=10
        )
        
        print(f"   Status: {scan_response.status_code}")
        if scan_response.status_code == 200:
            result = scan_response.json()
            print("   SUCCESS! Receipt scanned successfully:")
            print(f"   - Description: {result['data']['description']}")
            print(f"   - Amount: ${result['data']['amount']}")
            print(f"   - Date: {result['data']['date']}")
            print(f"   - Category: {result['data']['category']}")
            print(f"   - Merchant: {result['data']['merchant']}")
            print(f"   - Confidence: {result['confidence']:.2f}")
        else:
            print(f"   Error: {scan_response.text}")
        
        # Test adding the scanned expense
        print("\n3. Testing expense addition...")
        if scan_response.status_code == 200:
            result = scan_response.json()
            expense_data = {
                "description": result['data']['description'],
                "amount": result['data']['amount'],
                "category": result['data']['category'],
                "date": result['data']['date']
            }
            
            add_response = requests.post(
                "http://localhost:5003/api/expenses",
                json=expense_data,
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            print(f"   Status: {add_response.status_code}")
            if add_response.status_code == 200:
                expense = add_response.json()
                print(f"   SUCCESS! Expense added with ID: {expense['id']}")
            else:
                print(f"   Error: {add_response.text}")
        
        print("\n" + "=" * 50)
        print("Test completed!")
        
    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect to the API server.")
        print("Make sure the backend is running on port 5003.")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_receipt_scanning()
