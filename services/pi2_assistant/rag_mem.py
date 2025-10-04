import json
from pathlib import Path
from typing import Any, Dict, List, Optional

# Lightweight RAG + Memory utilities (no external deps required)

class RagIndex:
  def __init__(self, index_path: Path):
    self.index_path = index_path
    self.items: List[Dict[str, Any]] = []  # [{id,title,text,meta,vec}]

  def load(self):
    try:
      if self.index_path.exists():
        data = json.loads(self.index_path.read_text(encoding='utf-8'))
        self.items = data.get('items', [])
    except Exception:
      self.items = []

  def save(self):
    try:
      self.index_path.parent.mkdir(parents=True, exist_ok=True)
      self.index_path.write_text(json.dumps({'items': self.items}, ensure_ascii=False, indent=2), encoding='utf-8')
    except Exception:
      pass

  def _embed(self, text: str, dim: int = 256) -> List[float]:
    # Simple hashing vectorizer (fallback-friendly)
    v = [0.0] * dim
    for tok in (text or '').lower().split():
      h = sum(ord(c) for c in tok) % dim
      v[h] += 1.0
    return v

  @staticmethod
  def _cos(a: List[float], b: List[float]) -> float:
    if not a or not b:
      return 0.0
    s = 0.0; na = 0.0; nb = 0.0
    L = min(len(a), len(b))
    for i in range(L):
      ai = a[i]; bi = b[i]
      s += ai * bi; na += ai * ai; nb += bi * bi
    if na == 0 or nb == 0:
      return 0.0
    return s / ((na ** 0.5) * (nb ** 0.5))

  def add_doc(self, title: str, text: str, meta: Optional[Dict[str, Any]] = None):
    vec = self._embed(text or title)
    self.items.append({
      'id': f'doc-{len(self.items)+1}',
      'title': title,
      'text': text,
      'meta': meta or {},
      'vec': vec,
    })

  def top_k(self, query: str, k: int = 3, threshold: float = 0.15) -> List[Dict[str, Any]]:
    qv = self._embed(query)
    scored = []
    for it in self.items:
      sc = self._cos(qv, it.get('vec') or [])
      scored.append((sc, it))
    scored.sort(key=lambda x: x[0], reverse=True)
    return [it for (sc, it) in scored[:k] if sc >= threshold]


class MemoryStore:
  def __init__(self, states_dir: Path):
    self.states_dir = states_dir

  def _mem_path(self, user_id: str) -> Path:
    return self.states_dir / f"{user_id}_mem.json"

  def load(self, user_id: str) -> List[Dict[str, Any]]:
    path = self._mem_path(user_id)
    if not path.exists():
      return []
    try:
      data = json.loads(path.read_text(encoding='utf-8'))
      return data.get('items', [])
    except Exception:
      return []

  def save(self, user_id: str, items: List[Dict[str, Any]]):
    path = self._mem_path(user_id)
    try:
      path.write_text(json.dumps({'items': items}, ensure_ascii=False, indent=2), encoding='utf-8')
    except Exception:
      pass

  def add(self, user_id: str, text: str, tags: Optional[List[str]] = None, ts: Optional[str] = None):
    items = self.load(user_id)
    items.append({'text': text, 'tags': tags or [], 'ts': ts})
    # Keep last 200
    if len(items) > 200:
      items = items[-200:]
    self.save(user_id, items)

