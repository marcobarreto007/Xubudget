import requests
import json

def test_chat_endpoint():
    url = "http://127.0.0.1:5002/api/chat"
    headers = {"Content-Type": "application/json", "X-API-Key": "your-api-key"}
    data = {"message": "I spent 5 dollars on coffee at starbucks"}
    
    print("Testing chat endpoint...")
    try:
        response = requests.post(url, headers=headers, json=data)
        print(f"Status Code: {response.status_code}")
        print(f"Response: {response.text}")
        return response
    except Exception as e:
        print(f"Error: {e}")
        return None

if __name__ == "__main__":
    test_chat_endpoint()