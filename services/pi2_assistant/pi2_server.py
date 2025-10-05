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
import unicodedata
from typing import Any, Dict, List, Optional, Tuple
from uuid import uuid4
from copy import deepcopy

import requests
from requests.exceptions import Timeout, ConnectionError

from rag_mem import RagIndex, MemoryStore
from xu_guard import is_recent_duplicate

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

# Diretorio de states
STATES_DIR = Path(__file__).parent / "states"
STATES_DIR.mkdir(exist_ok=True)

CATEGORIES_PATH = Path(__file__).parent / "categories.json"
DEFAULT_EMOJI = "??"
STATE_LOCK = threading.Lock()

MEMORY_STORE = MemoryStore(STATES_DIR)
RAG_INDEX_PATH = STATES_DIR / "rag_index.json"
RAG_INDEX = RagIndex(RAG_INDEX_PATH)
try:
    RAG_INDEX.load()
except Exception as exc:
    logger.warning("Failed loading RAG index: %s", exc)


def _bootstrap_rag_corpus() -> None:
    kb_path = Path(__file__).parent / "financial_knowledge_base.md"
    if not kb_path.exists():
        return
    if RAG_INDEX.items:
        return
    try:
        text = kb_path.read_text(encoding="utf-8")
        RAG_INDEX.add_doc(title="financial_knowledge", text=text, meta={"source": "knowledge_base"})
        RAG_INDEX.save()
    except Exception as exc:
        logger.warning("Failed bootstrapping RAG corpus: %s", exc)


_bootstrap_rag_corpus()

OLLAMA_HOST = os.getenv("OLLAMA_HOST", "http://localhost:11434")
OLLAMA_MODEL = os.getenv("OLLAMA_MODEL", "deepseek-r1:7b")
OLLAMA_TIMEOUT = 10


def _load_categories() -> List[Dict[str, Any]]:
    if not CATEGORIES_PATH.exists():
        return []
    with open(CATEGORIES_PATH, "r", encoding="utf-8") as f:
        return json.load(f)


CATEGORIES = _load_categories()
CATEGORY_BY_ID = {cat.get("id", "").lower(): cat for cat in CATEGORIES if cat.get("id")}
CATEGORY_BY_NAME = {cat.get("name", "").lower(): cat for cat in CATEGORIES if cat.get("name")}


UI_PRIMARY_CATEGORY_NAMES = [
    "Groceries",
    "Food & Dining",
    "Rent/Mortgage",
    "Transport Apps",
    "Electricity",
    "Internet/Phone",
    "Entertainment",
    "Shopping",
]

BASE_SYSTEM_PROMPT = """You are Xuzinha, a smart and supportive financial assistant for Xubudget.

PERSONALITY:
- Friendly but direct - you give real advice, not just validation
- Always respond in concise English unless the user explicitly insists on another language
- Encouraging without being preachy - celebrate wins, be honest about challenges
- Smart about money - you understand psychology of spending and saving
- Slightly playful - use light humor when appropriate, but stay professional

YOUR ROLE:
- Use the provided financial snapshot/state to ground every answer and quote exact numbers when relevant
- Help users track expenses and stay within budget
- Suggest practical ways to save money
- Point out spending patterns (good or bad)
- Encourage better financial habits
- Provide context like "That's $X over budget" or "Great job, $X under budget!"

STYLE:
- Keep responses short (1-3 sentences)
- Base amounts on the supplied context; never guess missing numbers
- When the user asks about their balance or how much they have, answer with the "Available to spend" value from the context
- Ask clarifying questions only when key information is absent
- If the user is overspending consistently, gently point it out
- If the user is doing well, acknowledge it genuinely

"""


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


def _normalize_merchant_name(raw: Optional[str]) -> str:
    if not raw:
        return ""
    text = unicodedata.normalize('NFKD', raw).encode('ascii', 'ignore').decode('ascii')
    text = re.sub(r"[^a-z0-9]+", " ", text.lower()).strip()
    return text


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


def _extract_period_from_path(path: Path, user_id: str) -> Optional[str]:
    stem = path.stem
    if not stem.startswith(f"{user_id}_"):
        return None
    parts = stem.rsplit('_', 2)
    if len(parts) < 3:
        return None
    year, month = parts[-2], parts[-1]
    if not (year.isdigit() and month.isdigit()):
        return None
    return f"{year}_{month}"


def _list_state_files(user_id: str) -> List[Tuple[str, Path]]:
    items: List[Tuple[str, Path]] = []
    for path in STATES_DIR.glob(f"{user_id}_*.json"):
        period_key = _extract_period_from_path(path, user_id)
        if period_key:
            items.append((period_key, path))
    items.sort(key=lambda item: item[0])
    return items


def _latest_state_path(user_id: str) -> Optional[Tuple[str, Path]]:
    items = _list_state_files(user_id)
    return items[-1] if items else None


def _start_new_period_from_template(
    template_state: Dict[str, Any],
    user_id: str,
    month_key: str,
    previous_period: Optional[str],
) -> Dict[str, Any]:
    budget_value = float(template_state.get('budget', 0.0) or 0.0)
    new_state: Dict[str, Any] = {
        'user_id': user_id,
        'currency': template_state.get('currency', 'CAD'),
        'budget': budget_value,
        'monthly_spent': 0.0,
        'remaining': budget_value,
        'history': [],
        'incomes': [],
        'goals': deepcopy(template_state.get('goals', [])),
        'category_budgets': deepcopy(template_state.get('category_budgets', {})),
        'settings': deepcopy(template_state.get('settings', {})),
        'icons': deepcopy(template_state.get('icons', [])),
        'active_icons': deepcopy(template_state.get('active_icons', [])),
        'merchant_rules': deepcopy(template_state.get('merchant_rules', {})),
        'subcategory_budgets': deepcopy(template_state.get('subcategory_budgets', {})),
        'period': month_key,
        'previous_period': previous_period,
        'period_started_at': datetime.now().isoformat(),
    }
    return new_state


def _available_periods_for_user(user_id: str, current_period: Optional[str] = None) -> List[str]:
    periods = [key for key, _ in _list_state_files(user_id)]
    if current_period and current_period not in periods:
        periods.append(current_period)
    return sorted(set(periods))


def _format_period_label(period_key: str) -> str:
    try:
        dt = datetime.strptime(period_key, '%Y_%m')
        return dt.strftime('%B %Y')
    except Exception:
        return period_key


def _period_payloads(user_id: str, current_period: str) -> List[Dict[str, Any]]:
    periods = _available_periods_for_user(user_id, current_period)
    payloads: List[Dict[str, Any]] = []
    for key in periods:
        payloads.append({
            'id': key,
            'label': _format_period_label(key),
            'is_current': key == current_period,
        })
    return payloads


def _period_key_to_external(period_key: str) -> str:
    return period_key.replace('_', '-')


def _period_key_from_external(period: str) -> str:
    candidate = (period or '').strip().replace('-', '_')
    if not re.fullmatch(r"\d{4}_[0-1]\d", candidate):
        raise ValueError(f"Invalid period format: {period}")
    month = int(candidate[-2:])
    if month < 1 or month > 12:
        raise ValueError(f"Invalid month in period: {period}")
    return candidate


def _period_key_to_datetime(period_key: str) -> datetime:
    return datetime.strptime(period_key, '%Y_%m')


def _period_start_end(period_key: str) -> Tuple[datetime, datetime]:
    start = _period_key_to_datetime(period_key).replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    days_in_month = monthrange(start.year, start.month)[1]
    end = start + timedelta(days=days_in_month)
    return start, end


def _previous_period_key(period_key: str) -> Optional[str]:
    dt = _period_key_to_datetime(period_key)
    prev_month = dt.replace(day=1) - timedelta(days=1)
    return _month_key(prev_month) if prev_month.year >= 1970 else None


def _next_period_key(period_key: str) -> str:
    dt = _period_key_to_datetime(period_key)
    days_in_month = monthrange(dt.year, dt.month)[1]
    next_month = dt.replace(day=1) + timedelta(days=days_in_month)
    return _month_key(next_month)


def _normalize_period_param(period: Optional[str]) -> Optional[str]:
    if period is None:
        return None
    return _period_key_from_external(period)


def _current_period_key() -> str:
    return _month_key()


def _period_context_payload(user_id: str, current_period: str) -> List[Dict[str, Any]]:
    payloads = _period_payloads(user_id, current_period)
    for entry in payloads:
        entry['id'] = _period_key_to_external(entry['id'])
    return sorted(payloads, key=lambda item: item['id'], reverse=True)


def _parse_timestamp(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    try:
        return datetime.fromisoformat(value.replace("Z", ""))
    except Exception:
        return None


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
    state.setdefault("merchant_rules", {})
    state.setdefault("subcategory_budgets", {})

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

    # Recalculate totals
    _recalculate_totals(state, user_id)

    return state


def _recalculate_totals(state: Dict[str, Any], user_id: str) -> None:
    """Recalculate all totals and derived fields"""
    period_key = state.get("period") or _current_period_key()
    period_start, period_end = _period_start_end(period_key)
    
    expenses = [e for e in state.get("history", []) if e.get("type") == "expense"]
    incomes = [i for i in state.get("history", []) if i.get("type") == "income"] + state.get("incomes", [])

    monthly_expenses: List[Dict[str, Any]] = []
    for exp in expenses:
        ts = _parse_timestamp(exp.get("timestamp"))
        if ts and period_start <= ts < period_end:
            monthly_expenses.append(exp)

    total_spent = sum(e["amount"] for e in monthly_expenses)
    state["monthly_spent"] = round(total_spent, 2)

    budgets = state.get("category_budgets", {})
    if not budgets and CATEGORIES:
        budgets = {cat["id"]: float(cat.get("budget", 0.0) or 0.0) for cat in CATEGORIES}
        state["category_budgets"] = budgets

    total_budget = state.get("budget") or sum(budgets.values())
    state["budget"] = round(total_budget, 2)
    state["remaining"] = round(total_budget - total_spent, 2)

    spend_by_category: Dict[str, Dict[str, Any]] = defaultdict(lambda: {"spent": 0.0, "transactions": 0})
    merchants: Counter[str] = Counter()
    for exp in monthly_expenses:
        cat_id = exp.get("category") or "other"
        spend_by_category[cat_id]["spent"] += exp["amount"]
        spend_by_category[cat_id]["transactions"] += 1
        merchant = exp.get("merchant") or exp.get("description") or "Unknown"
        merchants[merchant.strip() or "Unknown"] += 1

    state["_category_totals"] = spend_by_category
    state["_top_merchants"] = merchants


def load_user_state(
    user_id: str = "default",
    period: Optional[str] = None,
    create_if_missing: bool = True,
) -> Dict[str, Any]:
    month_key = period or _current_period_key()
    if "-" in month_key:
        month_key = _period_key_from_external(month_key)
    if not re.fullmatch(r"\d{4}_[0-1]\d", month_key):
        raise ValueError(f"Invalid period format: {month_key}")

    monthly_path = _state_file(user_id, month_key)
    legacy_path = _legacy_state_file(user_id)

    raw: Dict[str, Any]
    source_path: Path

    if monthly_path.exists():
        raw = json.loads(monthly_path.read_text(encoding="utf-8"))
        source_path = monthly_path
    else:
        if not create_if_missing:
            raise FileNotFoundError(f"State for period {month_key} not found")

        template_state: Optional[Dict[str, Any]] = None
        previous_period: Optional[str] = None

        monthly_path.parent.mkdir(parents=True, exist_ok=True)

        template_entry: Optional[Tuple[str, Path]] = None
        prev_key = _previous_period_key(month_key)
        if prev_key:
            prev_path = _state_file(user_id, prev_key)
            if prev_path.exists():
                template_entry = (prev_key, prev_path)

        if template_entry is None:
            latest_entry = _latest_state_path(user_id)
            if latest_entry:
                template_entry = latest_entry

        if template_entry:
            previous_period, template_path = template_entry
            template_raw = json.loads(template_path.read_text(encoding="utf-8"))
            template_state = _ensure_state_schema(template_raw, user_id)
            previous_period = template_state.get("period") or previous_period
        elif legacy_path.exists():
            template_raw = json.loads(legacy_path.read_text(encoding="utf-8"))
            template_state = _ensure_state_schema(template_raw, user_id)
            previous_period = template_state.get("period") or _extract_period_from_path(legacy_path, user_id)

        if template_state is not None:
            raw = _start_new_period_from_template(template_state, user_id, month_key, previous_period)
            source_path = monthly_path
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
    if not state.get("period"):
        derived_period = _extract_period_from_path(source_path, user_id)
        state["period"] = derived_period or month_key
    state.setdefault("period_started_at", datetime.now().isoformat())
    if "previous_period" not in state:
        state["previous_period"] = None
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
    user_id = state.get("user_id", "default")
    period_key = state.get("period") or _current_period_key()
    try:
        period_start, period_end = _period_start_end(period_key)
    except ValueError:
        period_key = _current_period_key()
        period_start, period_end = _period_start_end(period_key)
        state["period"] = period_key

    state["_path"] = state.get("_path") or _state_file(user_id, period_key)

    expenses = [e for e in state.get("history", []) if e.get("type") == "expense"]
    incomes = [i for i in state.get("history", []) if i.get("type") == "income"] + state.get("incomes", [])

    for entry in expenses + incomes:
        entry["amount"] = float(entry.get("amount", 0.0) or 0.0)
        entry["timestamp"] = entry.get("timestamp") or datetime.now().isoformat()
        entry.setdefault("id", str(uuid4()))

    monthly_expenses: List[Dict[str, Any]] = []
    for exp in expenses:
        ts = _parse_timestamp(exp.get("timestamp"))
        if ts and period_start <= ts < period_end:
            monthly_expenses.append(exp)

    total_spent = sum(e["amount"] for e in monthly_expenses)
    state["monthly_spent"] = round(total_spent, 2)

    budgets = state.get("category_budgets", {})
    if not budgets and CATEGORIES:
        budgets = {cat["id"]: float(cat.get("budget", 0.0) or 0.0) for cat in CATEGORIES}
        state["category_budgets"] = budgets

    total_budget = state.get("budget") or sum(budgets.values())
    state["budget"] = round(total_budget, 2)
    state["remaining"] = round(total_budget - total_spent, 2)

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

    for cat_id, totals in spend_by_category.items():
        if cat_id not in CATEGORY_BY_ID:
            icon_entry = {
                "id": cat_id,
                "name": cat_id.replace("_", " " ).title(),
                "emoji": DEFAULT_EMOJI,
                "budget": round(float(state["category_budgets"].get(cat_id, 0.0)), 2),
                "spent": round(float(totals["spent"]), 2),
                "transactions": totals["transactions"],
                "active": cat_id in state.get("active_icons", []),
            }
            icons.append(icon_entry)

    icons.sort(key=lambda x: (-x["active"], -x["spent"]))
    state["icons"] = icons

    days_in_month = monthrange(period_start.year, period_start.month)[1]
    now = datetime.now()
    is_current_period = period_key == _current_period_key()
    day_index = now.day if is_current_period else days_in_month
    days_remaining = max(0, days_in_month - day_index) if is_current_period else 0

    state["period_start"] = period_start.isoformat()
    state["period_end"] = (period_end - timedelta(seconds=1)).isoformat()
    state["period_label"] = _format_period_label(period_key)
    state["days_in_period"] = days_in_month
    state["day_index"] = day_index
    state["days_remaining"] = days_remaining
    state["is_current_period"] = is_current_period
    state["next_period"] = _period_key_to_external(_next_period_key(period_key))
    if state.get("previous_period"):
        try:
            prev_internal = _period_key_from_external(_period_key_to_external(state["previous_period"]))
            state["previous_period"] = prev_internal
        except ValueError:
            pass
    state["available_periods"] = _period_context_payload(user_id, period_key)

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


def _load_state_for_request(request: Request, period: Optional[str], allow_create: bool = True) -> Dict[str, Any]:
    user_id = _get_user_id(request)
    normalized: Optional[str] = None
    if period:
        try:
            normalized = _normalize_period_param(period)
        except ValueError as exc:
            raise HTTPException(status_code=400, detail=str(exc)) from exc

    create = allow_create and (normalized is None or normalized == _current_period_key())
    try:
        return load_user_state(user_id, period=normalized, create_if_missing=create)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="Period not found")


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


def _expense_public(exp: Dict[str, Any]) -> Dict[str, Any]:
    cat_payload = _category_payload(exp.get("category"))
    return {
        "id": exp.get("id"),
        "amount": round(float(exp.get("amount", 0.0)), 2),
        "description": exp.get("description"),
        "category": exp.get("category"),
        "category_name": cat_payload.get("name"),
        "emoji": cat_payload.get("emoji", DEFAULT_EMOJI),
        "timestamp": exp.get("timestamp"),
        "merchant": exp.get("merchant") or "",
    }



def _income_public(inc: Dict[str, Any]) -> Dict[str, Any]:
    description = inc.get("description") or inc.get("source") or "Income"
    return {
        "id": inc.get("id"),
        "amount": round(float(inc.get("amount", 0.0)), 2),
        "source": inc.get("source") or description,
        "description": description,
        "timestamp": inc.get("timestamp"),
    }



def _find_expense_entry(state: Dict[str, Any], expense_id: str) -> Optional[Dict[str, Any]]:
    for entry in state.get("history", []):
        if entry.get("id") == expense_id and entry.get("type", "expense") == "expense":
            return entry
    return None



def _find_income_entries(state: Dict[str, Any], income_id: str) -> Tuple[Optional[Dict[str, Any]], Optional[Dict[str, Any]]]:
    primary = None
    for inc in state.get("incomes", []):
        if inc.get("id") == income_id:
            primary = inc
            break
    history_entry = None
    for entry in state.get("history", []):
        if entry.get("id") == income_id and entry.get("type") == "income":
            history_entry = entry
            break
    return primary, history_entry



def _remove_entry(items: List[Dict[str, Any]], entry_id: str, type_filter: Optional[str] = None) -> bool:
    for index, entry in enumerate(list(items)):
        if entry.get("id") == entry_id and (type_filter is None or entry.get("type") == type_filter):
            del items[index]
            return True
    return False



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
                "emoji": "??",
            })
        events.append(entry)

    events.sort(key=lambda e: e.get("timestamp", ""), reverse=True)
    return events[:limit]


def _build_dashboard_summary(state: Dict[str, Any]) -> Dict[str, Any]:
    totals = state.get("_category_totals", {})
    categories_payload: List[Dict[str, Any]] = []
    overall_budget = 0.0
    overall_spent = 0.0

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
        overall_budget += budget
        overall_spent += spent

    for cat in CATEGORIES:
        cat_id = cat.get("id")
        if not cat_id or cat_id in totals:
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
        overall_budget += budget

    categories_payload.sort(key=lambda c: c["spent"], reverse=True)
    primary = categories_payload[:8]
    secondary = categories_payload[8:]

    ui_total_budget = 0.0
    ui_total_spent = 0.0
    ui_category_ids: List[str] = []
    for name in UI_PRIMARY_CATEGORY_NAMES:
        cat_entry = CATEGORY_BY_NAME.get(name.lower())
        if not cat_entry:
            continue
        cat_id = cat_entry.get("id")
        if not cat_id:
            continue
        budget = float(state["category_budgets"].get(cat_id, cat_entry.get("budget", 0.0) or 0.0))
        ui_total_budget += budget
        ui_total_spent += float(totals.get(cat_id, {}).get("spent", 0.0))
        ui_category_ids.append(cat_id)

    if not ui_category_ids:
        ui_category_ids = [c.get("id") for c in primary if c.get("id")]
        ui_total_budget = overall_budget
        ui_total_spent = overall_spent

    ui_available = ui_total_budget - ui_total_spent

    period_key = state.get("period") or _current_period_key()
    period_label = state.get("period_label") or _format_period_label(period_key)
    period_external = _period_key_to_external(period_key)
    days_in_period = state.get("days_in_period") or monthrange(*_period_key_to_datetime(period_key).timetuple()[:2])[1]
    day_index = state.get("day_index") or days_in_period
    days_remaining = state.get("days_remaining")
    if days_remaining is None:
        days_remaining = max(0, days_in_period - day_index)

    day_index_safe = day_index if day_index else 1
    daily_pace = (ui_total_spent / day_index_safe) if day_index_safe else 0.0
    daily_target = (ui_total_budget / days_in_period) if days_in_period else 0.0
    delta_pct = ((daily_pace - daily_target) / daily_target) * 100 if daily_target else 0.0

    top_merchants = [
        {"name": merchant, "count": count}
        for merchant, count in state.get("_top_merchants", Counter()).most_common(5)
    ]

    recent_expenses = _list_expenses(state, 8)

    previous_period = state.get("previous_period")
    if previous_period:
        try:
            previous_period = _period_key_to_external(previous_period)
        except ValueError:
            previous_period = None

    next_period = state.get("next_period") or _period_key_to_external(_next_period_key(period_key))

    available_periods = state.get("available_periods") or _period_context_payload(state.get("user_id", "default"), period_key)

    return {
        "user_id": state.get("user_id"),
        "currency": state.get("currency", "CAD"),
        "period": period_external,
        "period_label": period_label,
        "period_start": state.get("period_start"),
        "period_end": state.get("period_end"),
        "days_in_period": days_in_period,
        "day_index": day_index,
        "days_remaining": days_remaining,
        "is_current_period": state.get("is_current_period", period_key == _current_period_key()),
        "previous_period": previous_period,
        "next_period": next_period,
        "available_periods": available_periods,
        "total_budget": round(ui_total_budget, 2),
        "total_spent": round(ui_total_spent, 2),
        "available_amount": round(ui_available, 2),
        "daily_pace": round(daily_pace, 2),
        "daily_delta_pct": round(delta_pct, 2),
        "primary_categories": primary,
        "secondary_categories": secondary,
        "top_merchants": top_merchants,
        "recent_expenses": recent_expenses,
        "overall_totals": {
            "budget": round(overall_budget, 2),
            "spent": round(overall_spent, 2),
            "available": round(overall_budget - overall_spent, 2),
        },
        "ui_primary_category_ids": ui_category_ids,
        "ui_total_budget": round(ui_total_budget, 2),
        "ui_total_spent": round(ui_total_spent, 2),
        "ui_available_amount": round(ui_available, 2),
    }


def _build_safe_to_spend(summary: Dict[str, Any]) -> Dict[str, Any]:
    days_in_period = summary.get("days_in_period") or monthrange(datetime.now().year, datetime.now().month)[1]
    day_index = summary.get("day_index") or datetime.now().day
    days_remaining = summary.get("days_remaining")
    if days_remaining is None:
        days_remaining = max(1, days_in_period - day_index + 1)
    total_budget = summary.get("total_budget", 0.0)
    total_spent = summary.get("total_spent", 0.0)
    available = summary.get("available_amount", total_budget - total_spent)
    daily_target = (total_budget / days_in_period) if days_in_period else 0.0
    remaining_days = max(1, days_remaining)
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
            f"Biggest expense so far: {top.get('name')} with {spent:.2f}. "
            f"You used {pct:.0f}% of this category's budget."
        )
    if summary.get("total_spent", 0.0) <= 0:
        return "No expenses recorded this month. Great job keeping the budget!"
    return "Keep tracking your expenses to maintain budget control."


def _build_category_analysis(state: Dict[str, Any], category_name: str) -> Dict[str, Any]:
    category_id = _normalize_category(category_name)
    cat_payload = CATEGORY_BY_ID.get(category_id) or CATEGORY_BY_NAME.get(category_id)
    display_name = (cat_payload or {}).get("name", category_name.title())
    budget = float(state.get("category_budgets", {}).get(category_id, (cat_payload or {}).get("budget", 0.0) or 0.0))

    now = datetime.now()
    month_start = datetime(now.year, now.month, 1)
    next_month = datetime(now.year, now.month, monthrange(now.year, now.month)[1]) + timedelta(days=1)

    expenses: List[Dict[str, Any]] = []
    for entry in state.get("history", []):
        if entry.get("type") != "expense":
            continue
        ts = _parse_timestamp(entry.get("timestamp"))
        if not ts:
            continue
        if _normalize_category(entry.get("category")) != category_id:
            continue
        expenses.append({"ts": ts, **entry})

    monthly = [e for e in expenses if month_start <= e["ts"] < next_month]
    monthly_total = sum(e.get("amount", 0.0) for e in monthly)
    tx_count = len(monthly)
    avg_tx = monthly_total / tx_count if tx_count else 0.0

    recent_cut = month_start - timedelta(days=90)
    recent_expenses = [e for e in expenses if e["ts"] >= recent_cut]
    recent_months = { (e["ts"].year, e["ts"].month) for e in recent_expenses } or {(now.year, now.month)}
    avg_recent = (sum(e.get("amount", 0.0) for e in recent_expenses) / max(len(recent_months), 1)) if recent_expenses else 0.0

    merchant_counter: Counter[str] = Counter()
    for e in monthly:
        merchant_name = e.get("merchant") or e.get("description") or "Unknown"
        merchant_counter[merchant_name.strip() or "Unknown"] += e.get("amount", 0.0)
    top_merchants = [
        {"name": name, "total": round(amount, 2)}
        for name, amount in merchant_counter.most_common(5)
    ]

    recent_transactions = [
        {
            "timestamp": e["ts"].isoformat(),
            "amount": round(e.get("amount", 0.0), 2),
            "description": e.get("description", ""),
            "merchant": e.get("merchant") or "",
        }
        for e in sorted(monthly, key=lambda item: item["ts"], reverse=True)[:10]
    ]

    remaining = budget - monthly_total
    if budget <= 0.0:
        spoken = f"You spent ${monthly_total:.2f} on {display_name} this month."
    elif monthly_total > budget:
        spoken = f"You exceeded the budget for {display_name} by ${abs(remaining):.2f}."
    else:
        spoken = f"You used ${monthly_total:.2f} of ${budget:.2f} on {display_name}. ${remaining:.2f} remaining."

    return {
        "category": display_name,
        "category_id": category_id,
        "month_spent": round(monthly_total, 2),
        "month_budget": round(budget, 2),
        "transaction_count": tx_count,
        "avg_tx": round(avg_tx, 2),
        "avg_recent": round(avg_recent, 2),
        "top_merchants": top_merchants,
        "recent_transactions": recent_transactions,
        "spoken": spoken,
    }


def _add_expense(state: Dict[str, Any], amount: float, description: str, category: Optional[str], timestamp: Optional[str] = None, merchant: Optional[str] = None) -> Dict[str, Any]:
    state.setdefault("merchant_rules", {})
    merchant_display = merchant or description or ""
    merchant_key = _normalize_merchant_name(merchant_display)

    normalized_category = _normalize_category(category)
    if merchant_key:
        learned = state["merchant_rules"].get(merchant_key)
        if learned and (not category or normalized_category == "other"):
            normalized_category = _normalize_category(learned)

    expense = {
        "id": str(uuid4()),
        "type": "expense",
        "amount": float(amount),
        "description": description,
        "category": normalized_category,
        "timestamp": timestamp or datetime.now().isoformat(),
        "merchant": merchant_display,
    }

    if merchant_key and normalized_category not in (None, "other"):
        existing = state["merchant_rules"].get(merchant_key)
        if not existing:
            state["merchant_rules"][merchant_key] = normalized_category

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


class UpdateExpenseRequest(BaseModel):
    user_id: Optional[str] = None
    amount: Optional[float] = None
    description: Optional[str] = None
    category: Optional[str] = None
    timestamp: Optional[str] = None
    merchant: Optional[str] = None


class UpdateIncomeRequest(BaseModel):
    user_id: Optional[str] = None
    amount: Optional[float] = None
    source: Optional[str] = None
    description: Optional[str] = None
    timestamp: Optional[str] = None


class GoalCreateRequest(BaseModel):
    user_id: Optional[str] = None
    name: str
    target_amount: float
    saved_amount: Optional[float] = 0.0
    status: Optional[str] = "active"


class GoalUpdateRequest(BaseModel):
    user_id: Optional[str] = None
    name: Optional[str] = None
    target_amount: Optional[float] = None
    saved_amount: Optional[float] = None
    status: Optional[str] = None

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


class SetBudgetRequest(BaseModel):
    user_id: Optional[str] = None
    budget: float


class SubcategoryBudgetRequest(BaseModel):
    user_id: Optional[str] = None
    category: str
    subcategory: str
    monthly_budget: float


class ReclassifyRequest(BaseModel):
    user_id: Optional[str] = None
    expense_id: str
    new_category: str


class MemoryItemPayload(BaseModel):
    user_id: Optional[str] = None
    text: str
    tags: Optional[List[str]] = None


class RagDocPayload(BaseModel):
    title: str
    text: str
    meta: Optional[Dict[str, Any]] = None


class MerchantLearnRequest(BaseModel):
    user_id: Optional[str] = None
    merchant: str
    category: str


class IntentRequest(BaseModel):
    text: str
    user_id: Optional[str] = None


# --- Endpoints basicos ---
@app.get("/healthz")
async def healthz():
    return {"ok": True, "timestamp": datetime.now().isoformat()}


@api.get("/healthz")
async def api_healthz():
    return await healthz()


@api.get("/categories")
async def get_categories():
    return {"categories": CATEGORIES}


@api.get("/state")
async def get_state(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    return _state_public(state)


@api.get("/timeline")
async def timeline(request: Request, days: int = Query(30, ge=1, le=180), limit: int = Query(200, ge=1, le=1000), period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
    items = _timeline_items(state, days, limit)
    return items


@api.get("/expenses")
async def list_expenses(request: Request, limit: int = Query(50, ge=1, le=500), period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
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


@api.patch("/expenses/{expense_id}")
async def update_expense(expense_id: str, payload: UpdateExpenseRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    entry = _find_expense_entry(state, expense_id)
    if not entry:
        raise HTTPException(status_code=404, detail="Expense not found")

    if payload.amount is not None:
        entry["amount"] = float(payload.amount)
    if payload.description is not None:
        entry["description"] = payload.description
    if payload.category is not None:
        entry["category"] = _normalize_category(payload.category)
    if payload.timestamp is not None:
        entry["timestamp"] = payload.timestamp
    if payload.merchant is not None:
        entry["merchant"] = payload.merchant

    _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "expense": _expense_public(entry), "state": _state_public(state)}


@api.delete("/expenses/{expense_id}")
async def delete_expense(expense_id: str, user_id: str = Query("default", alias="user_id")):
    state = load_user_state(user_id)
    history = state.get("history", [])
    if not _remove_entry(history, expense_id, type_filter="expense"):
        raise HTTPException(status_code=404, detail="Expense not found")

    _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "expense_id": expense_id, "state": _state_public(state)}


@api.get("/incomes")
async def list_incomes(request: Request, limit: int = Query(50, ge=1, le=500), period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
    items = _list_incomes(state, limit)
    return {"items": items, "total": len(state.get("incomes", []))}


@api.post("/add_income")
async def add_income(payload: AddIncomeRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    income = _add_income(state, payload.amount, payload.source, payload.timestamp)
    return {"status": "ok", "income": income, "state": _state_public(state)}


@api.patch("/incomes/{income_id}")
async def update_income(income_id: str, payload: UpdateIncomeRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    primary, history_entry = _find_income_entries(state, income_id)
    if not primary and not history_entry:
        raise HTTPException(status_code=404, detail="Income not found")

    targets = [entry for entry in (primary, history_entry) if entry]
    if payload.amount is not None:
        for entry in targets:
            entry["amount"] = float(payload.amount)
    if payload.source is not None:
        for entry in targets:
            entry["source"] = payload.source
            entry["description"] = payload.description or payload.source or entry.get("description")
    if payload.description is not None:
        for entry in targets:
            entry["description"] = payload.description
    if payload.timestamp is not None:
        for entry in targets:
            entry["timestamp"] = payload.timestamp

    _refresh_financials(state)
    save_user_state(state)
    current = primary or history_entry
    return {"status": "ok", "income": _income_public(current), "state": _state_public(state)}


@api.delete("/incomes/{income_id}")
async def delete_income(income_id: str, user_id: str = Query("default", alias="user_id")):
    state = load_user_state(user_id)
    primary, history_entry = _find_income_entries(state, income_id)
    removed = False
    if primary and _remove_entry(state.get("incomes", []), income_id):
        removed = True
    if history_entry and _remove_entry(state.get("history", []), income_id, type_filter="income"):
        removed = True
    if not removed:
        raise HTTPException(status_code=404, detail="Income not found")

    _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "income_id": income_id, "state": _state_public(state)}


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


@api.post("/set_budget")
async def set_budget(payload: SetBudgetRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    state["budget"] = float(payload.budget)
    _refresh_financials(state)
    save_user_state(state)
    return _state_public(state)


@api.get("/budget_structure")
async def budget_structure(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    public_state = _state_public(state)
    return {
        "user_id": user_id,
        "total_budget": state.get("budget", 0.0),
        "category_budgets": state.get("category_budgets", {}),
        "subcategory_budgets": state.get("subcategory_budgets", {}),
        "icons": public_state.get("icons", []),
    }


@api.post("/set_subcategory_budget_v2")
async def set_subcategory_budget_v2(payload: SubcategoryBudgetRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    cat_id = _normalize_category(payload.category)
    sub_id = _normalize_category(payload.subcategory)
    state.setdefault("subcategory_budgets", {}).setdefault(cat_id, {})[sub_id] = float(payload.monthly_budget)
    save_user_state(state)
    return {
        "status": "ok",
        "category": cat_id,
        "subcategory": sub_id,
        "monthly_budget": float(payload.monthly_budget),
    }


@api.get("/periods")
async def list_periods(request: Request):
    user_id = _get_user_id(request)
    items: List[Dict[str, Any]] = []
    seen: set[str] = set()

    for period_key, _ in reversed(_list_state_files(user_id)):
        try:
            state = load_user_state(user_id, period=period_key, create_if_missing=False)
        except FileNotFoundError:
            continue
        summary = _build_dashboard_summary(state)
        items.append({
            "period": summary.get("period"),
            "label": summary.get("period_label"),
            "total_spent": summary.get("total_spent"),
            "total_budget": summary.get("total_budget"),
            "available_amount": summary.get("available_amount"),
            "expense_count": len(state.get("history", [])),
            "is_current": summary.get("is_current_period", False),
            "days_remaining": summary.get("days_remaining"),
        })
        if summary.get("period"):
            seen.add(summary["period"])

    current_key = _current_period_key()
    current_external = _period_key_to_external(current_key)
    if current_external not in seen:
        state = load_user_state(user_id, period=current_key, create_if_missing=True)
        summary = _build_dashboard_summary(state)
        items.insert(0, {
            "period": summary.get("period"),
            "label": summary.get("period_label"),
            "total_spent": summary.get("total_spent"),
            "total_budget": summary.get("total_budget"),
            "available_amount": summary.get("available_amount"),
            "expense_count": len(state.get("history", [])),
            "is_current": summary.get("is_current_period", True),
            "days_remaining": summary.get("days_remaining"),
        })

    items.sort(key=lambda item: item["period"], reverse=True)
    return {"periods": items}


@api.get("/period/{period}")
async def get_period(period: str, request: Request):
    state = _load_state_for_request(request, period, allow_create=False)
    summary = _build_dashboard_summary(state)
    return {
        "summary": summary,
        "state": _state_public(state),
    }


@api.get("/dashboard_summary")
async def dashboard_summary(request: Request, period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
    summary = _build_dashboard_summary(state)
    return summary


@api.get("/safe_to_spend")
async def safe_to_spend(request: Request, period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
    summary = _build_dashboard_summary(state)
    return _build_safe_to_spend(summary)


@api.get("/category_analysis/{category_name}")
async def category_analysis(category_name: str, request: Request, period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
    return _build_category_analysis(state, category_name)


@api.get("/daily_briefing")
async def daily_briefing(request: Request):
    user_id = _get_user_id(request)
    state = load_user_state(user_id)
    summary = _build_dashboard_summary(state)
    text = _build_daily_briefing(summary)
    return {"date": datetime.now().strftime("%Y-%m-%d"), "text": text}


@api.get("/goals")
async def list_goals(request: Request, period: Optional[str] = Query(None)):
    state = _load_state_for_request(request, period, allow_create=True)
    return {"items": state.get("goals", [])}


@api.post("/goals")
async def create_goal(payload: GoalCreateRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    goal = {
        "id": str(uuid4()),
        "name": payload.name,
        "target_amount": float(payload.target_amount),
        "saved_amount": float(payload.saved_amount or 0.0),
        "status": payload.status or "active",
        "created_at": datetime.now().isoformat(),
    }
    state.setdefault("goals", []).append(goal)
    save_user_state(state)
    return {"status": "ok", "goal": goal, "state": _state_public(state)}


@api.patch("/goals/{goal_id}")
async def update_goal(goal_id: str, payload: GoalUpdateRequest):
    user_id = payload.user_id or "default"
    state = load_user_state(user_id)
    goals = state.setdefault("goals", [])
    goal = next((g for g in goals if g.get("id") == goal_id), None)
    if not goal:
        raise HTTPException(status_code=404, detail="Goal not found")

    if payload.name is not None:
        goal["name"] = payload.name
    if payload.target_amount is not None:
        goal["target_amount"] = float(payload.target_amount)
    if payload.saved_amount is not None:
        goal["saved_amount"] = float(payload.saved_amount)
    if payload.status is not None:
        goal["status"] = payload.status

    save_user_state(state)
    return {"status": "ok", "goal": goal, "state": _state_public(state)}


@api.delete("/goals/{goal_id}")
async def delete_goal(goal_id: str, user_id: str = Query("default", alias="user_id")):
    state = load_user_state(user_id)
    goals = state.get("goals", [])
    new_goals = [g for g in goals if g.get("id") != goal_id]
    if len(new_goals) == len(goals):
        raise HTTPException(status_code=404, detail="Goal not found")
    state["goals"] = new_goals
    save_user_state(state)
    return {"status": "ok", "goal_id": goal_id, "state": _state_public(state)}


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
        return {"type": "create_goal", "reply": f"Goal created: {goal['name']} ({goal['target_amount']:.2f})", "goal": goal}

    if any(keyword in lower for keyword in ["spent", "spend", "expense", "bought", "paid"]):
        if not amount:
            raise HTTPException(status_code=400, detail="I didn't understand the expense amount")
        match = re.search(r"(?:on|em) ([a-zA-ZA-y\s]+)", text)
        category = match.group(1) if match else "other"
        expense = _add_expense(state, amount, text, category)
        return {
            "type": "add_expense",
            "reply": f"Expense of {amount:.2f} recorded in {expense['category_name']}",
            "expense": expense,
        }

    if any(keyword in lower for keyword in ["income", "received", "earned", "salary"]):
        if not amount:
            raise HTTPException(status_code=400, detail="I didn't understand the income amount")
        income = _add_income(state, amount, text)
        return {
            "type": "add_income",
            "reply": f"Income of {amount:.2f} recorded.",
            "income": income,
        }

    return {"type": "message", "reply": "Understood! I can record expenses, goals or income."}


@api.post("/intent")
async def intent_endpoint(payload: IntentRequest):
    user_id = payload.user_id or "default"
    result = _handle_intent(user_id, payload.text)
    return result

@api.get("/ai/rules")
async def ai_rules():
    return {"rules": FALLBACK_RULES}


@api.post("/ai/learn_merchant_category")
async def learn_merchant_category(payload: MerchantLearnRequest):
    user_id = payload.user_id or "default"
    normalized_merchant = _normalize_merchant_name(payload.merchant)
    if not normalized_merchant:
        raise HTTPException(status_code=400, detail="Merchant name cannot be empty")
    category_id = _normalize_category(payload.category)
    state = load_user_state(user_id)
    state.setdefault("merchant_rules", {})[normalized_merchant] = category_id

    updated = 0
    for entry in state.get("history", []):
        if entry.get("type") != "expense":
            continue
        entry_merchant = _normalize_merchant_name(entry.get("merchant") or entry.get("description"))
        if entry_merchant == normalized_merchant:
            entry["category"] = category_id
            updated += 1

    if updated:
        _refresh_financials(state)
    save_user_state(state)
    return {"status": "ok", "merchant": normalized_merchant, "category": category_id, "updated": updated}





# --- Ollama helpers ---
def check_ollama() -> bool:
    """Check if Ollama is running"""
    try:
        r = requests.get(f"{OLLAMA_HOST}/api/tags", timeout=3)
        return r.status_code == 200
    except Exception:
        return False


FALLBACK_RULES = [
    {
        "intent": "expense",
        "keywords": ["spent", "spend", "expense", "bought", "paid"],
        "response": "Expense noted! I'll categorize it automatically. Keep tracking every purchase!",
    },
    {
        "intent": "balance",
        "keywords": ["how much", "balance", "available", "have", "safe to spend"],
        "response": "Check the dashboard to see your live balance.",
    },
    {
        "intent": "tips",
        "keywords": ["save", "tip", "suggestion", "help", "advice"],
        "response": "Tip: Review the categories with the highest spend and set smaller goals. Small changes add up!",
    },
    {
        "intent": "greeting",
        "keywords": ["hello", "hi", "good morning", "good afternoon", "good evening"],
        "response": "Hello! I'm Xuzinha, your budget assistant. How can I help you today?",
    },
    {
        "intent": "spending",
        "keywords": ["how much can i spend", "safe to spend", "available to spend", "budget left"],
        "response": "Check your safe-to-spend amount on the dashboard. It shows exactly how much you can spend without going over budget.",
    },
]


def fallback_response(prompt: str) -> str:
    """Rule-based fallback"""
    p = (prompt or "").lower()
    for rule in FALLBACK_RULES:
        if any(word in p for word in rule["keywords"]):
            return rule["response"]
    return "I understand! Check the dashboard for detailed information. How else can I help you with your budget?"


def chat_ollama(prompt: str, user_id: str = "default", state: Optional[Dict[str, Any]] = None) -> str:
    """Chat with Ollama, enriched with state, memory and RAG context"""
    if not prompt:
        return "I need a message to help."

    if not check_ollama():
        logger.warning("Ollama offline, using fallback")
        return fallback_response(prompt)

    context_sections: List[str] = []
    summary: Optional[Dict[str, Any]] = None
    formatter = None

    if state:
        try:
            summary = _build_dashboard_summary(state)
            currency_code = (summary.get("currency") or state.get("currency") or "USD").upper()
            symbol_map = {"USD": "$", "CAD": "$", "BRL": "R$", "EUR": "\u20ac", "GBP": "\u00a3"}
            currency_symbol = symbol_map.get(currency_code)

            def fmt_amount(amount):
                value = float(amount or 0.0)
                formatted = f"{value:,.2f}"
                if currency_symbol:
                    return f"{currency_symbol}{formatted}"
                return f"{currency_code} {formatted}"

            formatter = fmt_amount
            total_budget = summary.get("total_budget")
            total_spent = summary.get("total_spent")
            available = summary.get("available_amount")
            ui_ids = set(summary.get("ui_primary_category_ids") or [])
            top_candidates = summary.get("primary_categories", [])
            if ui_ids:
                top = [cat for cat in top_candidates if cat.get('id') in ui_ids][:3]
            else:
                top = top_candidates[:3]

            pieces = []
            if total_budget is not None:
                pieces.append(f"Total monthly budget: {fmt_amount(total_budget)}")
            if total_spent is not None:
                pieces.append(f"Spent so far: {fmt_amount(total_spent)}")
            if available is not None:
                pieces.append(f"Available to spend: {fmt_amount(available)}")
            for cat in top:
                spent = cat.get('spent', 0.0)
                budget = cat.get('budget', 0.0)
                pieces.append(f"{cat.get('name')}: {fmt_amount(spent)} spent of {fmt_amount(budget)}")
            if pieces:
                context_sections.append("Current financial snapshot:\n- " + "\n- ".join(pieces))
        except Exception as exc:
            logger.debug("Failed to build summary context: %s", exc)

    memories = MEMORY_STORE.load(user_id)[-5:]
    if memories:
        mem_lines = [f"- {item.get('text')}" for item in memories if item.get('text')]
        if mem_lines:
            context_sections.append("Recent user notes:\n" + "\n".join(mem_lines))

    rag_hits: List[Dict[str, Any]] = []
    try:
        if RAG_INDEX.items:
            rag_hits = RAG_INDEX.top_k(prompt, k=3)
    except Exception as exc:
        logger.debug("RAG search failed: %s", exc)
    if rag_hits:
        rag_text = "\n".join(f"- {hit.get('text')}" for hit in rag_hits)
        context_sections.append("Additional knowledge:\n" + rag_text)


    context_block = "\n\n".join(section for section in context_sections if section).strip()


    temporal_lines: List[str] = [f"- Today: {datetime.now().strftime('%B %d, %Y')}" ]
    if summary:
        period_label = summary.get("period_label") or "Current Period"
        period_external = summary.get("period")
        if period_external:
            temporal_lines.append(f"- Current period: {period_label} ({period_external})")
        else:
            temporal_lines.append(f"- Current period: {period_label}")
        day_index = summary.get("day_index")
        days_in_period = summary.get("days_in_period")
        if day_index and days_in_period:
            temporal_lines.append(f"- Day {day_index} of {days_in_period}")
        days_remaining = summary.get("days_remaining")
        if days_remaining is not None:
            temporal_lines.append(f"- Days remaining: {days_remaining}")
        if formatter and summary.get("available_amount") is not None:
            temporal_lines.append(f"- Available to spend: {formatter(summary.get('available_amount'))}")
        previous_period = summary.get("previous_period")
        if previous_period:
            try:
                prev_label = _format_period_label(_period_key_from_external(previous_period))
            except ValueError:
                prev_label = previous_period
            temporal_lines.append(f"- Previous period: {prev_label}")
    else:
        current_key = _current_period_key()
        temporal_lines.append(f"- Current period: {_format_period_label(current_key)} ({_period_key_to_external(current_key)})")

    system_context = "CURRENT CONTEXT:\n" + "\n".join(temporal_lines)
    system = f"{system_context}\n\n{BASE_SYSTEM_PROMPT}"
    prompt_parts = [system, ""]
    if context_block:
        prompt_parts.append("Context:")
        prompt_parts.append(context_block)
    prompt_parts.append(f"User: {prompt}")
    prompt_parts.append("Xuzinha:")
    full_prompt = "\n".join(part for part in prompt_parts if part)

    try:
        r = requests.post(
            f"{OLLAMA_HOST}/api/generate",
            json={
                "model": OLLAMA_MODEL,
                "prompt": full_prompt,
                "stream": False,
                "options": {
                    "temperature": 0.7,
                    "num_predict": 200
                }
            },
            timeout=OLLAMA_TIMEOUT
        )
        r.raise_for_status()
        data = r.json()
        return data.get("response") or data.get("text") or fallback_response(prompt)
    except Exception as e:
        logger.error("Ollama error: %s", e)
        return fallback_response(prompt)


@api.post("/chat")
async def chat_endpoint(payload: ChatRequest, request: Request):
    user_id = payload.user_id or _get_user_id(request)
    state = load_user_state(user_id)

    message = (payload.message or "").strip()
    if is_recent_duplicate(user_id, message):
        return {"response": "That message already came through recently. All good!", "state": _state_public(state), "duplicate": True}

    lower = message.lower()
    if any(trigger in lower for trigger in ["lembra", "lembre", "lembrete", "nota", "memoriza"]):
        MEMORY_STORE.add(user_id, message, tags=["note"], ts=datetime.now().isoformat())

    # Try to handle as intent first
    try:
        intent_result = _handle_intent(user_id, message)
        if intent_result.get("type") in ["add_expense", "add_income", "create_goal"]:
            return {"response": intent_result.get("reply", ""), "spoken": intent_result.get("reply", ""), "state": _state_public(state), "intent_handled": True}
    except Exception as e:
        print(f"Intent handling failed: {e}")
    
    reply = chat_ollama(message, user_id=user_id, state=state)
    return {"response": reply, "spoken": reply, "state": _state_public(state)}


@api.post("/chat_legacy")
async def chat_legacy(payload: ChatRequest, request: Request):
    result = await chat_endpoint(payload, request)
    return {
        "reply": result.get("response"),
        "spoken": result.get("spoken", result.get("response")),
        "state": result.get("state"),
    }



@api.get("/memory")
async def list_memory(request: Request):
    user_id = _get_user_id(request)
    return {"items": MEMORY_STORE.load(user_id)}


@api.post("/memory")
async def add_memory(payload: MemoryItemPayload):
    user_id = payload.user_id or "default"
    MEMORY_STORE.add(user_id, payload.text, tags=payload.tags or [], ts=datetime.now().isoformat())
    return {"status": "ok"}


@api.post("/rag/add")
async def rag_add(doc: RagDocPayload):
    RAG_INDEX.add_doc(doc.title, doc.text, meta=doc.meta or {})
    try:
        RAG_INDEX.save()
    except Exception as exc:
        logger.warning("Failed saving RAG index: %s", exc)
    return {"status": "ok", "documents": len(RAG_INDEX.items)}


@api.get("/rag/search")
async def rag_search(q: str, k: int = 3):
    matches = RAG_INDEX.top_k(q, k=max(1, min(k, 10)))
    return {
        "results": [
            {
                "title": it.get("title"),
                "text": it.get("text"),
                "meta": it.get("meta", {}),
            }
            for it in matches
        ]
    }


@api.get("/ollama_test")
async def ollama_test():
    online = check_ollama()
    return {"status": "online" if online else "offline", "host": OLLAMA_HOST}


# Incluir router
app.include_router(api)

# Flutter static files (ULTIMO)
flutter_dir = Path(__file__).parent.parent.parent / "mobile_app" / "build" / "web"
if flutter_dir.exists():
    app.mount("/", StaticFiles(directory=str(flutter_dir), html=True), name="flutter")

# Run
if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="127.0.0.1", port=5002)

