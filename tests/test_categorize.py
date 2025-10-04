"""
Test categorization API specifically
"""

import requests
import json

def test_categorization():
    """Test the categorization functionality"""
    
    test_cases = [
        "eu gastei 120 no restaurante",
        "almoço no restaurante 45 reais",
        "gasolina 80 reais",
        "farmácia 25 reais",
        "supermercado 150 reais"
    ]
    
    try:
        print("Testing categorization API...")
        print("=" * 50)
        
        for i, text in enumerate(test_cases, 1):
            print(f"\n{i}. Testing: '{text}'")
            
            response = requests.post(
                "http://localhost:5003/api/categorize",
                json={"text": text},
                headers={"Content-Type": "application/json"},
                timeout=10
            )
            
            print(f"   Status: {response.status_code}")
            if response.status_code == 200:
                result = response.json()
                print(f"   Category: {result['category']}")
                print(f"   Confidence: {result['confidence']:.2f}")
            else:
                print(f"   Error: {response.text}")
        
        print("\n" + "=" * 50)
        print("Categorization test completed!")
        
    except requests.exceptions.ConnectionError:
        print("ERROR: Could not connect to the API server.")
        print("Make sure the backend is running on port 5003.")
    except Exception as e:
        print(f"ERROR: {e}")

if __name__ == "__main__":
    test_categorization()
