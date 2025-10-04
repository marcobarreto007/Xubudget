# REM (WHY): dropa duplicatas em janela curta; evita 2 cliques/enter+botão duplicarem lançamento
from time import monotonic
from typing import Tuple, Dict

_DUP_TTL = 3.0  # segundos
_cache: Dict[Tuple[str, str], float] = {}

def is_recent_duplicate(user_id: str, message: str) -> bool:
    key = (user_id or "default", (message or "").strip().lower())
    now = monotonic()
    last = _cache.get(key)
    _cache[key] = now
    return (last is not None) and (now - last) < _DUP_TTL