# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\web_search.py
# REM (WHY): dar "internet on" via DuckDuckGo (sem API paga), com top-N resultados

from ddgs import DDGS

def web_search(query: str, max_results: int = 5):
    results = []
    with DDGS() as ddg:
        for r in ddg.text(query, max_results=max_results):
            results.append({
                "title": r.get("title"),
                "url": r.get("href"),
                "snippet": r.get("body")
            })
    return results
