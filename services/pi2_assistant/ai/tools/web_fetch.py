# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\web_fetch.py
# REM (WHY): baixar página e extrair só o conteúdo "legível" (sem lixo de menu/anúncio)

import requests
from bs4 import BeautifulSoup

def web_fetch(url: str, max_chars: int = 4000):
    resp = requests.get(url, timeout=20, headers={"User-Agent":"Mozilla/5.0"})
    # REM: corrigir encoding para acentos
    if not resp.encoding or resp.encoding.lower() in ("latin-1","iso-8859-1"):
        resp.encoding = resp.apparent_encoding or "utf-8"
    # Extrair conteúdo principal usando BeautifulSoup
    soup = BeautifulSoup(resp.text, "html.parser")
    # Remover scripts, styles, etc
    for script in soup(["script", "style", "nav", "header", "footer", "aside", "noscript"]):
        script.decompose()
    # Tentar encontrar conteúdo principal (article, main, ou body)
    main_content = soup.find("article") or soup.find("main") or soup.find("body")
    if main_content:
        text = main_content.get_text(separator="\n", strip=True)
    else:
        text = soup.get_text(separator="\n", strip=True)
    text = " ".join(text.split())
    return text[:max_chars]
