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