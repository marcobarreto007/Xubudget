import os
import json
import logging
import math
import re
import threading
from calendar import monthrange
from collections import Counter, defaultdict
from datetime import datetime, timedelta
from pathlib import Path
from typing import Any, Dict, List, Optional
from uuid import uuid4

import requests
from requests.exceptions import Timeout, ConnectionError

from fastapi import FastAPI, Request, HTTPException, APIRouter, Query
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pydantic import BaseModel

# Logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("xubudget")

# FastAPI app
app = FastAPI(title="Xubudget API")

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Router com prefixo /api
api = APIRouter(prefix="/api")

# Diretório de states
STATES_DIR = Path(__file__).parent / "states"
STATES_DIR.mkdir(exist_ok=True)

CATEGORIES_PATH = Path(__file__).parent / "categories.json"
DEFAULT_EMOJI = "🧾"
STATE_LOCK = threading.Lock()

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "qwen2.5:1.5b-instruct")
OLLAMA_TIMEOUT = 10


def _load_categories() -> List[Dict[str, Any]]:
    if not CATEGORIES_PATH.exists():
        return []
    with open(CATEGORIES_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


CATEGORIES = _load_categories()
CATEGORY_BY_ID = {cat.get("id", "").lower(): cat for cat in CATEGORIES if cat.get("id")}
CATEGORY_BY_NAME = {cat.get("name", "").lower(): cat for cat in CATEGORIES if cat.get("name")}


def _slugify(text: Optional[str]) -> str:
    if not text:
        return "other"
    slug = re.sub(r"[^a-z0-9]+", "_", text.strip().lower())
    slug = re.sub(r"_+", "_", slug).strip("_")
    return slug or "other"


def _normalize_category(raw: Optional[str]) -> str:
    if not raw:
        return "other"
    candidate = raw.strip().lower()
    if candidate in CATEGORY_BY_ID:
        return CATEGORY_BY_ID[candidate]["id"]
    if candidate in CATEGORY_BY_NAME:
        return CATEGORY_BY_NAME[candidate]["id"]
    slug = _slugify(candidate)
    if slug in CATEGORY_BY_ID:
        return CATEGORY_BY_ID[slug]["id"]
    if slug in CATEGORY_BY_NAME:
        return CATEGORY_BY_NAME[slug]["id"]
    # try partial name match
    for cat in CATEGORIES:
        name_slug = _slugify(cat.get("name", ""))
        if name_slug == slug:
            return cat["id"]
    return slug


def _category_payload(cat_id: str) -> Dict[str, Any]:
    if not cat_id:
        cat_id = "other"
    lookup = CATEGORY_BY_ID.get(cat_id.lower())
    if lookup:
        return {
            "id": lookup.get("id", cat_id),
            "name": lookup.get("name", cat_id.title()),
            "emoji": lookup.get("emoji", DEFAULT_EMOJI),
            "budget": float(lookup.get("budget", 0.0)),
        }
    return {
        "id": cat_id,
        "name": cat_id.replace("_", " ").title(),
        "emoji": DEFAULT_EMOJI,
        "budget": 0.0,
    }


def _month_key(dt: Optional[datetime] = None) -> str:
    dt = dt or datetime.now()
    return f"{dt.year}_{dt.month:02d}"


def _state_file(user_id: str, month_key: Optional[str] = None) -> Path:
    month_key = month_key or _month_key()
    return STATES_DIR / f"{user_id}_{month_key}.json"


def _legacy_state_file(user_id: str) -> Path:
    return STATES_DIR / f"{user_id}.json"


def _ensure_state_schema(state: Dict[str, Any], user_id: str) -> Dict[str, Any]:
    state.setdefault("user_id", user_id)
    state.setdefault("currency", "CAD")
    state.setdefault("budget", 0.0)
    state.setdefault("monthly_spent", 0.0)
    state.setdefault("remaining", 0.0)
    state.setdefault("history", [])
    state.setdefault("incomes", [])
    state.setdefault("goals", [])
    state.setdefault("category_budgets", {})
    state.setdefault("settings", {})
    state.setdefault("icons", [])
    state.setdefault("active_icons", [])

    state["settings"].setdefault("budget_mode", "standard")

    # Normalize history entries
    for entry in state["history"]:
        entry.setdefault("id", str(uuid4()))
        entry.setdefault("type", "expense")
        entry["amount"] = float(entry.get("amount", 0.0) or 0.0)
        entry["timestamp"] = entry.get("timestamp") or datetime.now().isoformat()
        entry["description"] = entry.get("description") or entry.get("text") or ""
        entry["category"] = _normalize_category(entry.get("category") or entry.get("category_id"))
        if entry["type"] == "income":
            entry.setdefault("source", entry.get("description", "Income"))

    for income in state["incomes"]:
        income.setdefault("id", str(uuid4()))
        income.setdefault("type", "income")
        income["amount"] = float(income.get("amount", 0.0) or 0.0)
        income["timestamp"] = income.get("timestamp") or datetime.now().isoformat()
        income["source"] = income.get("source") or income.get("description") or "Income"

    # Normalize goals
    normalized_goals = []
    for goal in state["goals"]:
        goal.setdefault("id", str(uuid4()))
        goal["name"] = goal.get("name") or "Goal"
        goal["target_amount"] = float(goal.get("target_amount", 0.0) or 0.0)
        goal["saved_amount"] = float(goal.get("saved_amount", 0.0) or 0.0)
        goal["status"] = goal.get("status") or "active"
        goal["created_at"] = goal.get("created_at") or datetime.now().isoformat()
        normalized_goals.append(goal)
    state["goals"] = normalized_goals

    return state


def load_user_state(user_id: str = "default") -> Dict[str, Any]:
    now = datetime.now()
    month_key = _month_key(now)
    monthly_path = _state_file(user_id, month_key)
    legacy_path = _legacy_state_file(user_id)

    if monthly_path.exists():
        raw = json.loads(monthly_path.read_text(encoding="utf-8"))
        source_path = monthly_path
    elif legacy_path.exists():
        raw = json.loads(legacy_path.read_text(encoding="utf-8"))
        source_path = legacy_path
    else:
        raw = {
            "user_id": user_id,
            "budget": 0.0,
            "monthly_spent": 0.0,
            "remaining": 0.0,
            "history": [],
            "incomes": [],
            "goals": [],
            "category_budgets": {},
            "settings": {"budget_mode": "standard"},
            "icons": [],
            "active_icons": [],
        }
        source_path = monthly_path

    state = _ensure_state_schema(raw, user_id)
    state["_path"] = source_path
    _refresh_financials(state)
    return state


def save_user_state(state: Dict[str, Any]) -> None:
    path: Path = state.get("_path") or _state_file(state.get("user_id", "default"))
    state_copy = {k: v for k, v in state.items() if not k.startswith("_")}
    with STATE_LOCK:
        path.write_text(json.dumps(state_copy, ensure_ascii=False, indent=2), encoding="utf-8")
    logger.debug("State saved to %s", path)


def _refresh_financials(state: Dict[str, Any]) -> None:
    now = datetime.now()
    month_key = _month_key(now)
    state["_path"] = state.get("_path") or _state_file(state.get("user_id", "default"), month_key)

    expenses = [e for e in state.get("history", []) if e.get("type") == "expense"]
    incomes = [i for i in state.get("history", []) if i.get("type") == "income"] + state.get("incomes", [])

    for entry in expenses + incomes:
        entry["amount"] = float(entry.get("amount", 0.0) or 0.0)
        entry["timestamp"] = entry.get("timestamp") or datetime.now().isoformat()
        entry.setdefault("id", str(uuid4()))

    # Recalculate monthly totals
    month_start = datetime(now.year, now.month, 1)
    month_end = month_start + timedelta(days=40)
    month_end = datetime(month_end.year, month_end.month, 1)

    monthly_expenses = [
        e for e in expenses
        if month_start <= datetime.fromisoformat(e["timestamp"].replace("Z", "")) < month_end
    ]

    total_spent = sum(e["amount"] for e in monthly_expenses)
    state["monthly_spent"] = round(total_spent, 2)

    budgets = state.get("category_budgets", {})
    if not budgets and CATEGORIES:
        budgets = {cat["id"]: float(cat.get("budget", 0.0) or 0.0) for cat in CATEGORIES}
        state["category_budgets"] = budgets

    total_budget = state.get("budget") or sum(budgets.values())
    state["budget"] = round(total_budget, 2)
    state["remaining"] = round(total_budget - total_spent, 2)

    # Category totals
    spend_by_category: Dict[str, Dict[str, Any]] = defaultdict(lambda: {"spent": 0.0, "transactions": 0})
    merchants: Counter[str] = Counter()
    for exp in expenses:
        cat_id = exp.get("category") or "other"
        spend_by_category[cat_id]["spent"] += exp["amount"]
        spend_by_category[cat_id]["transactions"] += 1
        merchant = exp.get("merchant") or exp.get("description") or "Unknown"
        merchants[merchant.strip() or "Unknown"] += 1

    state["_category_totals"] = spend_by_category
    state["_top_merchants"] = merchants

    # Icons (synchronized with categories)
    icons = []
    for cat in CATEGORIES:
        cat_id = cat.get("id")
        totals = spend_by_category.get(cat_id, {"spent": 0.0, "transactions": 0})
        budget = state["category_budgets"].get(cat_id, cat.get("budget", 0.0) or 0.0)
        icon_entry = {
            "id": cat_id,
            "name": cat.get("name", cat_id.title()),
            "emoji": cat.get("emoji", DEFAULT_EMOJI),
            "budget": round(float(budget), 2),
            "spent": round(float(totals["spent"]), 2),
            "transactions": totals["transactions"],
            "active": cat_id in state.get("active_icons", []),
        }
        icons.append(icon_entry)

    # Include custom categories that may not exist in categories.json
    for cat_id, totals in spend_by_category.items():
        if cat_id not in CATEGORY_BY_ID:
            icon_entry = {
                "id": cat_id,
                "name": cat_id.replace("_", " ").title(),
                "emoji": DEFAULT_EMOJI,
                "budget": round(float(state["category_budgets"].get(cat_id, 0.0)), 2),
                "spent": round(float(totals["spent"]), 2),
                "transactions": totals["transactions"],
                "active": cat_id in state.get("active_icons", []),
            }
            icons.append(icon_entry)

    icons.sort(key=lambda x: (-x["active"], -x["spent"]))
    state["icons"] = icons


def _state_public(state: Dict[str, Any]) -> Dict[str, Any]:
    data = {k: v for k, v in state.items() if not k.startswith("_")}
    return json.loads(json.dumps(data, ensure_ascii=False))


def _get_user_id(request: Request, override: Optional[str] = None) -> str:
    if override:
        return override
    return (
        request.cookies.get("user_id")
        or request.headers.get("X-User-ID")
        or request.headers.get("X-USER-ID")
        or "default"
    )


def _list_expenses(state: Dict[str, Any], limit: int) -> List[Dict[str, Any]]:
    expenses = [e for e in state.get("history", []) if e.get("type") == "expense"]
    expenses.sort(key=lambda e: e.get("timestamp", ""), reverse=True)
    results = []
    for exp in expenses[:limit]:
        cat_payload = _category_payload(exp.get("category"))
        results.append({
            "id": exp.get("id"),
            "amount": round(float(exp.get("amount", 0.0)), 2),
            "description": exp.get("description"),
            "category": exp.get("category"),
            "category_name": cat_payload.get("name"),
            "emoji": cat_payload.get("emoji", DEFAULT_EMOJI),
            "timestamp": exp.get("timestamp"),
            "merchant": exp.get("merchant") or "",
        })
    return results


def _list_incomes(state: Dict[str, Any], limit: int) -> List[Dict[str, Any]]:
    incomes = [i for i in state.get("incomes", [])]
    # include income-type entries stored in history
    incomes.extend(e for e in state.get("history", []) if e.get("type") == "income")
    incomes.sort(key=lambda e: e.get("timestamp", ""), reverse=True)
    items = []
    for inc in incomes[:limit]:
        items.append({
            "id": inc.get("id"),
            "amount": round(float(inc.get("amount", 0.0)), 2),
            "description": inc.get("description") or inc.get("source") or "Income",
            "source": inc.get("source") or "Income",
            "timestamp": inc.get("timestamp"),
        })
    return items


def _timeline_items(state: Dict[str, Any], days: int, limit: int) -> List[Dict[str, Any]]:
    cutoff = datetime.now() - timedelta(days=days)
    events: List[Dict[str, Any]] = []
    for exp in state.get("history", []):
        ts = datetime.fromisoformat(exp.get("timestamp", datetime.now().isoformat()).replace("Z", ""))
        if ts < cutoff:
            continue
        entry = {
            "id": exp.get("id"),
            "type": exp.get("type", "expense"),
            "amount": round(float(exp.get("amount", 0.0)), 2),
            "description": exp.get("description"),
            "timestamp": exp.get("timestamp"),
        }
        if entry["type"] == "expense":
            cat_payload = _category_payload(exp.get("category"))
            entry.update({
                "category": exp.get("category"),
                "category_name": cat_payload.get("name"),
                "emoji": cat_payload.get("emoji", DEFAULT_EMOJI),
            })
        else:
            entry.update({
                "category": "income",
                "category_name": exp.get("source") or "Income",
                "emoji": "💰",
            })
        events.append(entry)

    events.sort(key=lambda e: e.get("timestamp", ""), reverse=True)
    return events[:limit]


def _build_dashboard_summary(state: Dict[str, Any]) -> Dict[str, Any]:
    totals = state.get("_category_totals", {})
    categories_payload: List[Dict[str, Any]] = []
    total_budget = 0.0
    total_spent = 0.0

    for cat_id, data in totals.items():
        cat_info = _category_payload(cat_id)
        budget = float(state["category_budgets"].get(cat_id, cat_info.get("budget", 0.0) or 0.0))
        spent = float(data.get("spent", 0.0))
        categories_payload.append({
            "id": cat_id,
            "name": cat_info.get("name"),
            "icon": cat_info.get("emoji", DEFAULT_EMOJI),
            "emoji": cat_info.get("emoji", DEFAULT_EMOJI),
            "budget": round(budget, 2),
            "spent": round(spent, 2),
            "remaining": round(budget - spent, 2),
            "transactions": data.get("transactions", 0),
        })
        total_budget += budget
        total_spent += spent

    # Include categories with budget but no spend
    for cat in CATEGORIES:
        cat_id = cat.get("id")
        if cat_id in totals:
            continue
        budget = float(state["category_budgets"].get(cat_id, cat.get("budget", 0.0) or 0.0))
        if budget <= 0:
            continue
        categories_payload.append({
            "id": cat_id,
            "name": cat.get("name"),
            "icon": cat.get("emoji", DEFAULT_EMOJI),
            "emoji": cat.get("emoji", DEFAULT_EMOJI),
            "budget": round(budget, 2),
            "spent": 0.0,
            "remaining": round(budget, 2),
            "transactions": 0,
        })
        total_budget += budget

    categories_payload.sort(key=lambda c: c["spent"], reverse=True)
    primary = categories_payload[:8]
    secondary = categories_payload[8:]

    now = datetime.now()
    days_in_month = monthrange(now.year, now.month)[1]
    day_index = now.day
    daily_pace = (total_spent / day_index) if day_index else 0.0
    daily_target = (total_budget / days_in_month) if days_in_month else 0.0
    delta_pct = 0.0
    if daily_target > 0:
        delta_pct = ((daily_pace - daily_target) / daily_target) * 100

    top_merchants = [
        {"name": merchant, "count": count}
        for merchant, count in state.get("_top_merchants", Counter()).most_common(5)
    ]

    recent_expenses = _list_expenses(state, 8)

    return {
        "user_id": state.get("user_id"),
        "currency": state.get("currency", "CAD"),
        "period": _month_key(),
        "total_budget": round(total_budget, 2),
        "total_spent": round(total_spent, 2),
        "available_amount": round(total_budget - total_spent, 2),
        "daily_pace": round(daily_pace, 2),
        "daily_delta_pct": round(delta_pct, 2),
        "primary_categories": primary,
        "secondary_categories": secondary,
        "top_merchants": top_merchants,
        "recent_expenses": recent_expenses,
    }


def _build_safe_to_spend(summary: Dict[str, Any]) -> Dict[str, Any]:
    now = datetime.now()
    days_in_month = monthrange(now.year, now.month)[1]
    day_index = now.day
    remaining_days = max(1, days_in_month - day_index + 1)
    total_budget = summary.get("total_budget", 0.0)
    total_spent = summary.get("total_spent", 0.0)
    available = summary.get("available_amount", total_budget - total_spent)
    daily_target = (total_budget / days_in_month) if days_in_month else 0.0
    safe_today = available / remaining_days if remaining_days else available
    predicted_month_end = total_spent + (safe_today * remaining_days)
    delta_vs_target = available - (daily_target * remaining_days)

    return {
        "safe_today": round(safe_today, 2),
        "predicted_month_end": round(predicted_month_end, 2),
        "delta_vs_target": round(delta_vs_target, 2),
    }


def _build_daily_briefing(summary: Dict[str, Any]) -> str:
    top_categories = summary.get("primary_categories", [])
    if top_categories:
        top = top_categories[0]
        spent = top.get("spent", 0.0)
        budget = top.get("budget", 0.0) or 1.0
        pct = min(100.0, (spent / budget) * 100 if budget else 0.0)
        return (
            f"Maior gasto até agora: {top.get('name')} com {spent:.2f}. "
            f"Você usou {pct:.0f}% do orçamento desta categoria."
        )
    if summary.get("total_spent", 0.0) <= 0:
        return "Nenhuma despesa registrada este mês. Bom trabalho em manter o orçamento!"
    return "Continue acompanhando suas despesas para manter o orçamento sob controle."


def _add_expense(state: Dict[str, Any], amount: float, description: str, category: Optional[str], timestamp: Optional[str] = None, merchant: Optional[str] = None) -> Dict[str, Any]:
    expense = {
        "id": str(uuid4()),
        "type": "expense",
        "amount": float(amount),
        "description": description,
        "category": _normalize_category(category),
        "timestamp": timestamp or datetime.now().isoformat(),
        "merchant": merchant,
    }
    state.setdefault("history", []).insert(0, expense)
    _refresh_financials(state)
    save_user_state(state)
    cat_payload = _category_payload(expense["category"])
    response = {
        "id": expense["id"],
        "amount": round(expense["amount"], 2),
        "description": expense["description"],
        "category": expense["category"],
        "category_name": cat_payload.get("name"),
        "emoji": cat_payload.get("emoji", DEFAULT_EMOJI),
        "timestamp": expense["timestamp"],
    }
    return response


def _add_income(state: Dict[str, Any], amount: float, source: str, timestamp: Optional[str] = None) -> Dict[str, Any]:
    income = {
        "id": str(uuid4()),
        "type": "income",
        "amount": float(amount),
        "source": source or "Income",
        "description": source or "Income",
        "timestamp": timestamp or datetime.now().isoformat(),
    }
    state.setdefault("incomes", []).insert(0, income)
    _refresh_financials(state)
    save_user_state(state)
    return {
        "id": income["id"],
        "amount": round(income["amount"], 2),
        "source": income["source"],
        "timestamp": income["timestamp"],
    }


class ChatRequest(BaseModel):
    message: str
    user_id: Optional[str] = None


class AddExpenseRequest(BaseModel):
    user_id: Optional[str] = None
    amount: float
    description: str
    category: Optional[str] = None
    subcategory: Optional[str] = None
    timestamp: Optional[str] = None
    merchant: Optional[str] = None


class AddIncomeRequest(BaseModel):
    user_id: Optional[str] = None
    amount: float
    source: str
    timestamp: Optional[str] = None


class BudgetModeRequest(BaseModel):
    user_id: Optional[str] = None
    mode: str


class ActivateIconRequest(BaseModel):
    user_id: Optional[str] = None
    category_id: str
    amount: Optional[float] = None


class SetCategoryBudgetRequest(BaseModel):
    user_id: Optional[str] = None
    category_id: str
    budget: float


class ReclassifyRequest(BaseModel):
    user_id: Optional[str] = None
    expense_id: str
    new_category: str


class IntentRequest(BaseModel):
    text: str
    user_id: Optional[str] = None


# --- Endpoints básicos ---
@app.get("/healthz")
async def healthz():
    return {"ok": True, "timestamp": datetime.now().isoformat()}


@api.get("/categories")
async def get_categories():
    return {"categories": CATEGORIES}


@api.get("/state")
async def get_state(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    return _state_public(state)


@api.get("/timeline")
async def timeline(request: Request, days: int = Query(30, ge=1, le=180), limit: int = Query(200, ge=1, le=1000)):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    items = _timeline_items(state, days, limit)
    return items


@api.get("/expenses")
async def list_expenses(request: Request, limit: int = Query(50, ge=1, le=500)):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    items = _list_expenses(state, limit)
    return {"items": items, "total": len(state.get("history", []))}


@api.post("/add_expense")
async def add_expense(payload: AddExpenseRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    expense = _add_expense(
        state,
        amount=payload.amount,
        description=payload.description,
        category=payload.subcategory or payload.category,
        timestamp=payload.timestamp,
        merchant=payload.merchant,
    )
    return {"status": "ok", "expense": expense, "state": _state_public(state)}


@api.get("/incomes")
async def list_incomes(request: Request, limit: int = Query(50, ge=1, le=500)):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    items = _list_incomes(state, limit)
    return {"items": items, "total": len(state.get("incomes", []))}


@api.post("/add_income")
async def add_income(payload: AddIncomeRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    income = _add_income(state, payload.amount, payload.source, payload.timestamp)
    return {"status": "ok", "income": income, "state": _state_public(state)}


@api.post("/set_budget_mode")
async def set_budget_mode(payload: BudgetModeRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    state["settings"]["budget_mode"] = payload.mode
    save_user_state(state)
    return {"status": "ok", "mode": payload.mode}


@api.post("/activate_icon")
async def activate_icon(payload: ActivateIconRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    cat_id = _normalize_category(payload.category_id)
    if payload.amount is not None:
        state["category_budgets"][cat_id] = float(payload.amount)
    if cat_id not in state.get("active_icons", []):
        state["active_icons"].append(cat_id)
    _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "category_id": cat_id}


@api.get("/icons")
async def list_icons(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    return {"items": state.get("icons", [])}


@api.post("/set_category_budget")
async def set_category_budget(payload: SetCategoryBudgetRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    cat_id = _normalize_category(payload.category_id)
    state["category_budgets"][cat_id] = float(payload.budget)
    _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "category_id": cat_id, "budget": float(payload.budget)}


@api.get("/dashboard_summary")
async def dashboard_summary(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    summary = _build_dashboard_summary(state)
    return summary


@api.get("/safe_to_spend")
async def safe_to_spend(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    summary = _build_dashboard_summary(state)
    return _build_safe_to_spend(summary)


@api.get("/daily_briefing")
async def daily_briefing(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    summary = _build_dashboard_summary(state)
    text = _build_daily_briefing(summary)
    return {"date": datetime.now().strftime("%Y-%m-%d"), "text": text}


@api.get("/goals")
async def list_goals(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    return {"items": state.get("goals", [])}


@api.post("/expense/reclassify")
async def reclassify_expense(payload: ReclassifyRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    target = None
    for entry in state.get("history", []):
        if entry.get("id") == payload.expense_id:
            target = entry
            break
    if not target:
        raise HTTPException(status_code=404, detail="Expense not found")
    target["category"] = _normalize_category(payload.new_category)
    _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "expense": {"id": target["id"], "category": target["category"]}}


def _parse_amount(text: str) -> Optional[float]:
    match = re.search(r"(\d+[\.,]?\d*)", text)
    if not match:
        return None
    value = match.group(1).replace(",", ".")
    try:
        return float(value)
    except ValueError:
        return None


def _handle_intent(user_id: str, text: str) -> Dict[str, Any]:
    state = load_user_state(user_id)
    lower = text.lower()
    amount = _parse_amount(lower)

    if any(keyword in lower for keyword in ["goal", "meta", "objetivo"]):
        if not amount:
            amount = 0.0
        goal = {
            "id": str(uuid4()),
            "name": text.title(),
            "target_amount": float(amount or 0.0),
            "saved_amount": 0.0,
            "status": "active",
            "created_at": datetime.now().isoformat(),
        }
        state.setdefault("goals", []).append(goal)
        save_user_state(state)
        return {"type": "create_goal", "reply": f"Meta criada: {goal['name']} ({goal['target_amount']:.2f})", "goal": goal}

    if any(keyword in lower for keyword in ["spent", "gastei", "spend", "comprei", "paguei"]):
        if not amount:
            raise HTTPException(status_code=400, detail="Não entendi o valor da despesa")
        match = re.search(r"(?:on|em) ([a-zA-ZÀ-ÿ\s]+)", text)
        category = match.group(1) if match else "other"
        expense = _add_expense(state, amount, text, category)
        return {
            "type": "add_expense",
            "reply": f"Despesa de {amount:.2f} registrada em {expense['category_name']}",
            "expense": expense,
        }

    if any(keyword in lower for keyword in ["income", "recebi", "ganhei"]):
        if not amount:
            raise HTTPException(status_code=400, detail="Não entendi o valor da renda")
        income = _add_income(state, amount, text)
        return {
            "type": "add_income",
            "reply": f"Receita de {amount:.2f} registrada.",
            "income": income,
        }

    return {"type": "message", "reply": "Entendido! Posso registrar despesas, metas ou receitas."}


@api.post("/intent")
async def intent_endpoint(payload: IntentRequest):
    user_id = payload.user_id or "default"
    result = _handle_intent(user_id, payload.text)
    return result


# --- Ollama helpers ---
def check_ollama() -> bool:
    """Check if Ollama is running"""
    try:
        r = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=3)
        return r.status_code == 200
    except Exception:
        return False


def fallback_response(prompt: str) -> str:
    """Rule-based fallback"""
    p = (prompt or "").lower()
    if any(w in p for w in ["gastar", "gastei", "comprei", "paguei", "spent"]):
        return "Despesa registrada! Vou categorizar automaticamente. Continue economizando! 💰"
    if any(w in p for w in ["quanto", "saldo", "disponível", "tenho", "balance"]):
        return "Consulte o dashboard para ver seu saldo atualizado em tempo real."
    if any(w in p for w in ["economizar", "dica", "sugestão", "ajuda", "tip"]):
        return "Dica: Revise categorias com maior gasto e defina metas menores. Pequenas mudanças, grandes resultados!"
    return "Entendido! Use o dashboard para mais detalhes. Como posso ajudar?"


def chat_ollama(prompt: str) -> str:
    """Chat with Ollama, fallback to rules"""
    if not check_ollama():
        logger.warning("Ollama offline, using fallback")
        return fallback_response(prompt)
    
    try:
        system = """You are Xuzinha, a smart and supportive financial assistant for Xubudget.

PERSONALITY:
- Friendly but direct - you give real advice, not just validation
- Bilingual (English/Portuguese) - respond in the user's language
- Encouraging without being preachy - celebrate wins, be honest about challenges
- Smart about money - you understand psychology of spending and saving
- Slightly playful - use light humor when appropriate, but stay professional

YOUR ROLE:
- Help users track expenses and stay within budget
- Suggest practical ways to save money
- Point out spending patterns (good or bad)
- Encourage better financial habits
- Provide context: "That's $X over budget" or "Great job, $X under budget!"

STYLE:
- Keep responses SHORT (1-3 sentences)
- Be specific with numbers when relevant
- Ask clarifying questions if needed
- If user is overspending consistently, gently point it out
- If user is doing well, acknowledge it genuinely

EXAMPLES:
User: "I spent $50 on coffee this week"
You: "That's $200/month on coffee - almost half your Entertainment budget. Want to set a weekly coffee limit?"

User: "Added $30 groceries"
You: "Got it! You're at $180/$400 for Groceries this month. Doing great."

User: "How can I save money?"
You: "Let's look at your top 3 spending categories first. Where do you think you could cut back?"

Now respond to the user naturally."""
        
        full_prompt = f"{system}\n\nUser: {prompt}\nXuzinha:"
        
        r = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={
                "model": OLLAMA_MODEL, 
                "prompt": full_prompt, 
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "num_predict": 150
                }
            },
            timeout=OLLAMA_TIMEOUT
        )
        r.raise_for_status()
        return r.json()["response"]
    except Exception as e:
        logger.error(f"Ollama error: {e}")
        return fallback_response(prompt)


@api.post("/chat")
async def chat_endpoint(payload: ChatRequest, request: Request):
    user_id = payload.user_id or _get_user_id(request)
    state = load_user_state(user_id)
    reply = chat_ollama(payload.message)
    return {"response": reply, "state": _state_public(state)}


@api.get("/ollama_test")
async def ollama_test():
    online = check_ollama()
    return {"status": "online" if online else "offline", "host": OLLAMA_HOST}


# Incluir router
app.include_router(api)

# Flutter static files (ÚLTIMO)
flutter_dir = Path(__file__).parent.parent.parent / "mobile_app" / "build" / "web"
if flutter_dir.exists():
    app.mount("/", StaticFiles(directory=str(flutter_dir), html=True), name="flutter")

# Run
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5002)
