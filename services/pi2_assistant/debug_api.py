import requests
import json

# Teste direto da função de categorização
response = requests.post(
    "http://127.0.0.1:5002/api/chat",
    headers={"Content-Type": "application/json", "X-API-Key": "your-api-key"},
    json={"message": "gastei 5 no starbucks"}
)

print("\n=== TESTE DE CATEGORIZAÇÃO ===")
print(f"Status: {response.status_code}")
print(f"Resposta: {json.dumps(response.json(), indent=2)}")
print("============================\n")
