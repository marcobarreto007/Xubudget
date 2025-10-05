# C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant\ai\tools\web_fetch.py
# REM (WHY): baixar página e extrair só o conteúdo "legível" (sem lixo de menu/anúncio)

import requests
from bs4 import BeautifulSoup
from readability import Document

def web_fetch(url: str, max_chars: int = 4000):
    resp = requests.get(url, timeout=20, headers={"User-Agent":"Mozilla/5.0"})
    # REM: corrigir encoding para acentos
    if not resp.encoding or resp.encoding.lower() in ("latin-1","iso-8859-1"):
        resp.encoding = resp.apparent_encoding or "utf-8"
    doc = Document(resp.text)
    html = doc.summary()
    text = BeautifulSoup(html, "html.parser").get_text(separator="\n")
    text = " ".join(text.split())
    return text[:max_chars]
