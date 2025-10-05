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