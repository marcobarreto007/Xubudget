export const API_BASE = process.env.REACT_APP_API_BASE || 'http://127.0.0.1:8000';

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
