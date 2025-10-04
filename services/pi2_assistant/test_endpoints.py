import requests

BASE_URL = "http://127.0.0.1:5002"

def sanitize(text):
    if text is None:
        return ""
    if not isinstance(text, str):
        text = str(text)
    return text.encode("ascii", "ignore").decode("ascii")

print("=" * 40)
print("ENDPOINT TESTS - XUBUDGET (DETAILED)")
print("=" * 40)

# Test 1: Health
r = requests.get(f"{BASE_URL}/healthz")
print(f"OK /healthz: {r.status_code} - {r.json()}")

# Test 2: Categories (with details)
r = requests.get(f"{BASE_URL}/api/categories")
print(f"\nOK /api/categories: {r.status_code}")
cats = r.json()
if isinstance(cats, dict) and "categories" in cats:
    categories_list = cats.get("categories", [])
else:
    categories_list = cats if isinstance(cats, list) else []
print(f"  -> {len(categories_list)} categories found")
print("  -> First 3 categories:")
for cat in categories_list[:3]:
    name = sanitize(cat.get("name", "N/A"))
    emoji = sanitize(cat.get("emoji", ""))
    subs = cat.get("subcategories")
    subs_count = len(subs) if isinstance(subs, (list, tuple)) else 0
    print(f"     - {name}: {emoji} ({subs_count} subcats)")

# Test 3: Category Analysis (with raw response)
r = requests.get(f"{BASE_URL}/api/category_analysis/Food")
print(f"\nOK /api_category_analysis/Food: {r.status_code}")
print(f"  -> Content-Type: {sanitize(r.headers.get('content-type'))}")
print("  -> Raw Response (first 500 chars):")
text_preview = sanitize(r.text[:500]).replace("\n", " ")
print(f"     {text_preview}")
try:
    data = r.json()
    print(f"  -> JSON parsed successfully: {list(data.keys())}")
except Exception as exc:
    print(f"  JSON parse error: {exc}")
