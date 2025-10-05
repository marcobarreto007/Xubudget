# FIX COMPLETO XUZINHA - MULTILÍNGUE + ANTI-LOOP

## Objetivo
Cortar "ruminação" do modelo, forçar JSON curto (2 frases), mapear pedidos de ação → db.*, finalizar após 1 chamada da mesma ferramenta, garantir frontend usa porta 8000 e refresha após modificações.

## PASSO 1 — Backend (AI)

### 1.1 Atualizar prompt base
**Arquivo:** `ai/prompts/xuzinha_base.txt`

```
Você é a Xuzinha 💜 — assistente financeira da família.
ESTILO: curto, direto, PT-BR. Máximo 2 frases objetivas. Sem "aula".
AÇÃO: pedidos com verbos (listar/ver/aumente/reduza/alterar/editar/zerar/apagar/setar)
devem usar ferramentas db.get_expenses, db.update_expense, db.set_category, db.reset.
Use RAG p/ contexto da família. Use web.search/web.fetch p/ fatos atuais.
FORMATO OBRIGATÓRIO DE SAÍDA:
{ "final_answer": "texto curto", "used_tools": ["..."] }
Nunca exponha raciocínio interno. Nunca crie tool_call se já recebeu OBS_TOOL.
```

### 1.2 Ajustar config do modelo
**Arquivo:** `config/ai_model.yaml`

```yaml
model: deepseek-r1:7b
provider: ollama
temperature: 0.3
max_tokens: 160
system_prompt_path: ai/prompts/xuzinha_base.txt

tools:
  - name: db.get_expenses
    args: {}
    desc: "Ler despesas atuais por categoria."
  - name: db.update_expense
    args: { category: "str", delta: "float" }
    desc: "Somar delta ao total da categoria."
  - name: db.set_category
    args: { category: "str", total: "float" }
    desc: "Definir total exato da categoria."
  - name: db.reset
    args: {}
    desc: "Zerar todas as categorias."
  - name: web.search
    args: { query: "str", max_results: "int" }
    desc: "Buscar fatos atuais."
  - name: web.fetch
    args: { url: "str", max_chars: "int" }
    desc: "Extrair texto legível."
  - name: rag.search
    args: { query: "str", k: "int" }
    desc: "Consultar base local."
  - name: budget.optimize
    args: { renda_mensal: "float", categorias: "dict", metas: "dict" }
    desc: "Sugerir orçamento equilibrado."

policy:
  prefer_db_for: ["listar","ver despesas","despesas por categoria","aumente","reduza","alterar","editar","zerar","apagar","apagar tudo","setar","definir"]
  ban_think_markup: true
  json_only: true
  max_steps: 3
  max_same_tool: 1
  response: { max_sentences: 2, max_chars: 180 }
```

### 1.3 Cliente Ollama JSON estrito
**Arquivo:** `ai/tools/ollama_client.py`

```python
import httpx

class OllamaClient:
    def __init__(self, model: str, temperature: float = 0.3, max_tokens: int = 160, base_url: str = "http://127.0.0.1:11434"):
        self.model = model
        self.temperature = temperature
        self.max_tokens = max_tokens
        self.base_url = base_url.rstrip("/")

    def generate(self, prompt: str, json_mode: bool = True) -> str:
        payload = {
            "model": self.model,
            "prompt": prompt,
            "options": {
                "temperature": self.temperature,
                "num_predict": self.max_tokens,
                "repeat_penalty": 1.2,
                "repeat_last_n": 64,
                "stop": ["OBS_TOOL", "USER:", "ASSISTANT:", "TOOL:"]
            },
            "stream": False
        }
        if json_mode:
            payload["format"] = "json"
        with httpx.Client(timeout=60) as client:
            r = client.post(f"{self.base_url}/api/generate", json=payload)
            r.raise_for_status()
            return r.json().get("response", "")
```

### 1.4 Detecção de idioma
**Arquivo:** `ai/tools/lang.py` (novo)

```python
from langdetect import detect, DetectorFactory
DetectorFactory.seed = 0

def detect_lang(text: str, default: str = "pt") -> str:
    try:
        code = detect(text or "")
        return (code or default).split("-")[0].lower()
    except Exception:
        return default

def lang_name(code: str) -> str:
    MAP = {
        "pt": "português do Brasil",
        "en": "inglês", 
        "es": "espanhol",
        "fr": "francês",
        "de": "alemão",
        "it": "italiano",
        "hi": "hindi",
        "ar": "árabe",
        "zh": "chinês",
        "ja": "japonês",
        "ko": "coreano",
    }
    return MAP.get(code, code)
```

### 1.5 Adaptador de despesas expandido
**Arquivo:** `ai/tools/db_adapter.py`

```python
import os, json, httpx
from collections import defaultdict

API_BASE = os.getenv("XU_API_BASE", "").rstrip("/")
DB_PATH  = os.getenv("XU_DB_PATH", r"C:\Xuzinha\data\expenses.json")
ALLOW_WRITE = os.getenv("XU_ALLOW_WRITE", "1") == "1"

def _api_get(path):
    url = f"{API_BASE}{path}"
    with httpx.Client(timeout=15) as c:
        r = c.get(url); r.raise_for_status(); return r.json()

def _api_post(path, payload):
    url = f"{API_BASE}{path}"
    with httpx.Client(timeout=15) as c:
        r = c.post(url, json=payload); r.raise_for_status(); return r.json()

def _file_read():
    if not os.path.exists(DB_PATH): return {"items":[]}
    return json.load(open(DB_PATH,"r",encoding="utf-8"))

def _file_write(data):
    if not ALLOW_WRITE: return False
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    json.dump(data, open(DB_PATH,"w",encoding="utf-8"), ensure_ascii=False, indent=2)
    return True

def _totais(items):
    bucket = defaultdict(float)
    for it in items:
        cat = (it.get("category") or "Uncategorized").strip()
        bucket[cat] += float(it.get("amount",0))
    return dict(bucket)

def db_get_expenses(args=None):
    if API_BASE:
        try:
            data = _api_get("/api/expenses")
            items = data.get("items") or data
            return {"source":"api","totals":_totais(items)}
        except Exception:
            pass
    data = _file_read()
    return {"source":"file","totals":_totais(data.get("items",[]))}

def db_update_expense(args):
    cat = (args or {}).get("category","").strip()
    delta = float((args or {}).get("delta",0))
    if not cat: return {"error":"categoria obrigatória"}
    if API_BASE:
        try: return {"source":"api","result":_api_post("/api/expenses/adjust", {"category":cat,"delta":delta})}
        except Exception: pass
    data = _file_read(); items = data.get("items",[])
    items.append({"id":"adj-"+cat,"category":cat,"amount":delta,"desc":"adjustment"})
    persisted = _file_write({"items":items})
    return {"source":"file","category":cat,"after":_totais(items).get(cat,0.0),"persisted":persisted}

def db_set_category(args):
    cat = (args or {}).get("category","").strip()
    total = float((args or {}).get("total",0))
    if not cat: return {"error":"categoria obrigatória"}
    if API_BASE:
        try: return {"source":"api","result":_api_post("/api/expenses/set", {"category":cat,"total":total})}
        except Exception: pass
    data = _file_read(); items = [i for i in data.get("items",[]) if (i.get("category") or "") != cat]
    items.append({"id":"set-"+cat,"category":cat,"amount":total,"desc":"set-total"})
    persisted = _file_write({"items":items})
    return {"source":"file","category":cat,"after":_totais(items).get(cat,0.0),"persisted":persisted}

def db_reset(args=None):
    if API_BASE:
        try: return {"source":"api","result":_api_post("/api/expenses/reset",{})}
        except Exception: pass
    persisted = _file_write({"items":[]})
    return {"source":"file","cleared":True,"persisted":persisted}
```

### 1.6 Roteador de intenção
**Arquivo:** `ai/tools/intent_router.py` (novo)

```python
import re

PATTERNS = {
    "list": re.compile(r"\b(listar|ver|mostrar).*(despesa|despesas|categoria)", re.I),
    "inc":  re.compile(r"\b(aumente|somar|acrescente|add|adicionar)\b.*\b([a-zçãéêíóôú ]+)\b.*\b(\d+[.,]?\d*)", re.I),
    "dec":  re.compile(r"\b(reduza|subtraia|remova|tirar)\b.*\b([a-zçãéêíóôú ]+)\b.*\b(\d+[.,]?\d*)", re.I),
    "set":  re.compile(r"\b(setar|definir|ajustar|colocar)\b.*\b([a-zçãéêíóôú ]+)\b.*\bpara\b.*\b(\d+[.,]?\d*)", re.I),
    "reset":re.compile(r"\b(zerar|apagar tudo|limpar tudo|resetar)\b", re.I),
}

def route(user_msg: str):
    m = PATTERNS["list"].search(user_msg)
    if m: return {"name":"db.get_expenses","args":{}}

    for key, sign in [("inc", +1), ("dec", -1)]:
        m = PATTERNS[key].search(user_msg)
        if m:
            cat = m.group(2).strip().title()
            val = float(m.group(3).replace(",","."))*sign
            return {"name":"db.update_expense","args":{"category":cat,"delta":val}}

    m = PATTERNS["set"].search(user_msg)
    if m:
        cat = m.group(2).strip().title()
        val = float(m.group(3).replace(",",".")) 
        return {"name":"db.set_category","args":{"category":cat,"total":val}}

    if PATTERNS["reset"].search(user_msg):
        return {"name":"db.reset","args":{}}

    return None
```

### 1.7 App principal com multilíngue
**Arquivo:** `app.py`

```python
import os, re, json, yaml, sys
from typing import Dict, Any, List
from fastapi import FastAPI
from pydantic import BaseModel
import uvicorn

sys.stdout.reconfigure(encoding='utf-8')

from ai.tools.ollama_client import OllamaClient
from ai.tools.web_search import web_search
from ai.tools.web_fetch import web_fetch
from ai.tools.finance_tools import budget_optimize
from ai.rag import store as rag_store
from ai.tools.db_adapter import db_get_expenses, db_update_expense, db_set_category, db_reset
from ai.tools.intent_router import route as intent_route
from ai.tools.lang import detect_lang, lang_name

CFG   = yaml.safe_load(open("config/ai_model.yaml","r",encoding="utf-8"))
SYSTEM= open(CFG["system_prompt_path"],"r",encoding="utf-8").read()
OLLAMA= OllamaClient(CFG["model"], CFG["temperature"], CFG["max_tokens"])

TOOLS = {
    "db.get_expenses": db_get_expenses,
    "db.update_expense": db_update_expense,
    "db.set_category": db_set_category,
    "db.reset": db_reset,
    "web.search": lambda a: web_search(a.get("query",""), int(a.get("max_results",5))),
    "web.fetch":  lambda a: web_fetch(a.get("url",""), int(a.get("max_chars",4000))),
    "rag.search": lambda a: rag_store.search(a.get("query",""), int(a.get("k",5))),
    "budget.optimize": lambda a: budget_optimize(float(a.get("renda_mensal",0.0)), dict(a.get("categorias",{})), dict(a.get("metas",{})))
}

POL  = CFG.get("policy",{})
PREF = [p.lower() for p in POL.get("prefer_db_for",[])]
BAN_THINK = POL.get("ban_think_markup", True)
MAX_STEPS = int(POL.get("max_steps",3))
MAX_SAME  = int(POL.get("max_same_tool",1))
RSTYLE = POL.get("response", {"max_sentences":2,"max_chars":180})

class ChatIn(BaseModel):  user_id: str; message: str
class ChatOut(BaseModel): final_answer: str; used_tools: List[str] = []

app = FastAPI(title="Xuzinha Core")

def _json_extract(s: str) -> Dict[str,Any]:
    if BAN_THINK: s = re.sub(r"<think>[\s\S]*?</think>","",s,flags=re.I)
    i,j=s.find("{"),s.rfind("}")
    if i>=0 and j>i:
        try: return json.loads(s[i:j+1])
        except: pass
    return {"final_answer": s.strip(), "used_tools":[]}

def _clamp(txt: str) -> str:
    txt = re.sub(r"\s+"," ",txt or "").strip()
    parts = re.split(r"(?<=[.!?])\s+", txt); txt=" ".join(parts[: int(RSTYLE.get("max_sentences",2))])
    limit = int(RSTYLE.get("max_chars",180))
    return (txt[:limit].rstrip()+"…") if len(txt)>limit else txt

def _force_finalize(used: List[str]) -> str:
    return f'Finalize agora em JSON: {{"final_answer":"...", "used_tools":{used}}}'

def _call_llm(messages: List[Dict[str,str]]) -> Dict[str,Any]:
    prompt = "".join(f"{m['role'].upper()}: {m['content']}\n" for m in messages)
    raw = OLLAMA.generate(prompt, json_mode=True)
    return _json_extract(raw)

def _prefer_db(text: str) -> bool:
    l = text.lower();  return any(k in l for k in PREF)

def agent(user_msg: str) -> ChatOut:
    user_code = detect_lang(user_msg, default="pt")
    user_lang = lang_name(user_code)

    INSTR = f"""{SYSTEM}
Responda no idioma do usuário: {user_lang}.
Ferramentas: {', '.join(TOOLS.keys())}
Regras:
- JSON obrigatório: {{"final_answer":"...", "used_tools":["..."]}}
- Ação de despesas → prefira db.*. Sem <think>. Curto.
"""

    # 0) Roteador de intenção: se reconhecer ação -> EXECUTA e encerra
    route = intent_route(user_msg)
    if route:
        result = TOOLS[route["name"]](route.get("args",{}))
        fa = _clamp(f"OK. {route['name']} executada.")
        return ChatOut(final_answer=fa, used_tools=[route["name"]])

    # 1) Fluxo LLM (apenas quando não for ação óbvia)
    msgs = [{"role":"system","content":INSTR},{"role":"user","content":user_msg}]
    used=[]; last_sig=None; same=0

    for _ in range(MAX_STEPS):
        out = _call_llm(msgs)

        if _prefer_db(user_msg) and "tool_call" not in out and "final_answer" not in out:
            out = {"tool_call":{"name":"db.get_expenses","args":{}}}

        if "tool_call" in out:
            name=out["tool_call"]["name"]; args=out["tool_call"].get("args",{})
            sig=(name, json.dumps(args, sort_keys=True)); same = same+1 if sig==last_sig else 0; last_sig=sig
            if same>=MAX_SAME:
                msgs += [{"role":"assistant","content":json.dumps(out,ensure_ascii=False)},
                         {"role":"user","content":_force_finalize(used)}]
                fin=_call_llm(msgs); return ChatOut(final_answer=_clamp(fin.get("final_answer","Concluído.")), used_tools=used)

            fn=TOOLS.get(name)
            if not fn: return ChatOut(final_answer=_clamp(f"Ferramenta '{name}' indisponível."), used_tools=used)
            result=fn(args); used.append(name)
            msgs += [{"role":"assistant","content":json.dumps(out,ensure_ascii=False)},
                     {"role":"user","content":f"OBS_TOOL {name}: {json.dumps(result,ensure_ascii=False)[:3000]}. {_force_finalize(used)}"}]
            continue

        if "final_answer" in out and out["final_answer"]:
            return ChatOut(final_answer=_clamp(out["final_answer"]), used_tools=out.get("used_tools",used))

        msgs.append({"role":"user","content":_force_finalize(used)})

    return ChatOut(final_answer=_clamp("Concluído."), used_tools=used)

@app.post("/api/chat/xuzinha", response_model=ChatOut)
def chat(inp: ChatIn): return agent(inp.message)

@app.get("/api/expenses/totals")
def totals(): return db_get_expenses({})

@app.get("/")
def root(): return {"ok":True, "service":"xuzinha-core", "tools":list(TOOLS.keys())}

if __name__=="__main__": uvicorn.run(app, host="127.0.0.1", port=8000)
```

## PASSO 2 — Frontend (React)

### 2.1 Serviço da IA
**Arquivo:** `xuzinha_dashboard/src/services/agent.ts` (novo)

```typescript
export const API_BASE = 'http://127.0.0.1:8000';

function clamp(t: string, max=180) { return t && t.length>max ? t.slice(0,max).trim()+'…' : (t||''); }

export async function sendToAgent(message: string) {
  const res = await fetch(`${API_BASE}/api/chat/xuzinha`, {
    method: 'POST',
    headers: {'Content-Type':'application/json'},
    body: JSON.stringify({ user_id: 'ui', message })
  }).then(r=>r.json());
  const text = clamp(res.final_answer || res.message || res.response || '');
  const tools: string[] = res.used_tools || [];
  return { text, tools };
}

export async function fetchTotals() {
  return fetch(`${API_BASE}/api/expenses/totals`).then(r=>r.json());
}
```

### 2.2 Atualizar ChatInterface
**Arquivo:** `xuzinha_dashboard/src/components/ChatInterface.tsx`

Substituir a lógica de envio por:

```typescript
import { sendToAgent, fetchTotals } from '../services/agent';

// Na função handleSendMessage, substituir:
const { text, tools } = await sendToAgent(currentInput);
addMessage({ role:'assistant', text });

if (tools.some(t => ['db.update_expense','db.set_category','db.reset'].includes(t))) {
  const data = await fetchTotals();
  // Atualizar estado com data.totals
  console.log('Budget refreshed:', data.totals);
}
```

## PASSO 3 — Validação

### 3.1 Instalar dependência
```bash
pip install langdetect==1.0.9
```

### 3.2 Testar no console do navegador
```javascript
// Listar
fetch('http://127.0.0.1:8000/api/chat/xuzinha',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:'ui',message:'listar despesas por categoria'})}).then(r=>r.json()).then(console.log)

// Aumentar
fetch('http://127.0.0.1:8000/api/chat/xuzinha',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:'ui',message:'aumente Food em 20'})}).then(r=>r.json()).then(console.log)

// Multilíngue
fetch('http://127.0.0.1:8000/api/chat/xuzinha',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({user_id:'ui',message:'Set Food to 100'})}).then(r=>r.json()).then(console.log)
```

**Esperado:**
- used_tools: ['db.get_expenses'] no #1
- used_tools: ['db.update_expense'] no #2  
- Resposta em inglês no #3
- Front atualiza após modificações
