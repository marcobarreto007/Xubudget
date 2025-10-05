# 🏗️ XUBUDGET BACKEND STRUCTURE - CURSOR AI REFERENCE

## 📋 **PROJECT OVERVIEW**

**Path**: `C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant`  
**Main File**: `pi2_server.py` (1,935 lines)  
**Architecture**: Monolithic FastAPI with APIRouter  
**Deployment**: Direct uvicorn (not containerized in production)  
**Database**: JSON files (no SQL/NoSQL)  
**AI**: Ollama HTTP integration with custom RAG  

---

## 🏗️ **CORE ARCHITECTURE**

### **FastAPI App Structure**
```python
# pi2_server.py - MAIN ENTRY POINT
app = FastAPI(title="Xubudget API")                    # Main app
api = APIRouter(prefix="/api")                         # API router
app.include_router(api)                                # Mount router
app.mount("/", StaticFiles(...), name="flutter")       # Flutter Web static files
```

### **Module Dependencies**
```
pi2_server.py (MAIN)
├── rag_mem.py (RAG system)
├── xu_guard.py (anti-duplication)
├── financial_knowledge_base.md (knowledge base)
├── categories.json (expense categories)
└── states/ (JSON persistence)
    ├── default.json (user state)
    ├── rag_index.json (RAG index)
    └── user_state.json (user data)
```

---

## 🧩 **FRONTEND INTEGRATION**

### **Flutter Web**
- **Access**: `http://127.0.0.1:5002/` (static files)
- **API Calls**: `http://127.0.0.1:5002/api/*`
- **Build Path**: `../mobile_app/build/web/`
- **Integration**: Served as static files at root

### **React Web**
- **Access**: `http://localhost:3000` (separate dev server)
- **API Calls**: `http://127.0.0.1:5002/api/*`
- **Integration**: Direct HTTP calls via axios

### **API Endpoints Used by Frontends**
```javascript
// Both frontends use same endpoints
GET  /api/expenses          // List expenses
POST /api/add_expense       // Add expense
GET  /api/state             // User state
POST /api/chat              // AI chat
GET  /api/categories        // Expense categories
POST /api/set_budget        // Set budget
```

---

## 🧠 **AI & RAG SYSTEM**

### **Ollama Integration**
```python
# Configuration
OLLAMA_HOST = "http://localhost:11434"
OLLAMA_MODEL = "qwen2.5:7b-instruct"
OLLAMA_TIMEOUT = 10

# Usage
def chat_ollama(prompt: str, user_id: str = "default") -> str:
    # HTTP request to Ollama API
    # NO FALLBACK when offline (404 error)
```

### **RAG System (rag_mem.py)**
```python
class RagIndex:
    def add_doc(title, text, meta)     # Add document
    def top_k(query, k=3)             # Search top-k results
    def save()                        # Persist to JSON
    def load()                        # Load from JSON

# Usage
RAG_INDEX = RagIndex(RAG_INDEX_PATH)
RAG_INDEX.add_doc("financial_knowledge", text, meta)
matches = RAG_INDEX.top_k("budget question", k=3)
```

### **RAG Endpoints**
```python
POST /api/rag/add          # Add document to RAG
GET  /api/rag/search       # Search RAG index
GET  /api/ollama_test      # Check Ollama status
```

---

## 💾 **DATA PERSISTENCE**

### **JSON File System**
```python
# User State
states/default.json = {
    "user_id": "default",
    "budget": 7900.0,
    "monthly_spent": 5.0,
    "remaining": 7895.0,
    "history": [...]
}

# RAG Index
states/rag_index.json = {
    "items": [
        {"id": "...", "title": "...", "text": "...", "vec": [...]}
    ]
}

# Categories
categories.json = [
    {"id": "food", "name": "Food", "emoji": "🍕", ...}
]
```

### **Memory Store**
```python
# rag_mem.py
class MemoryStore:
    def get(user_id)        # Get user memory
    def set(user_id, data)  # Set user memory
    def add_memory(...)     # Add memory entry
```

---

## 🔌 **API ENDPOINTS STRUCTURE**

### **Core Endpoints (37 total)**
```python
# Health & Status
GET  /api/healthz          # Health check
GET  /api/ollama_test      # Ollama status

# User State
GET  /api/state            # Get user state
GET  /api/timeline         # Get timeline

# Expenses
GET  /api/expenses         # List expenses
POST /api/add_expense      # Add expense
DELETE /api/expenses/{id}  # Delete expense

# Incomes
GET  /api/incomes          # List incomes
POST /api/add_income       # Add income
DELETE /api/incomes/{id}   # Delete income

# Budget Management
POST /api/set_budget       # Set budget
GET  /api/budget_structure # Get budget structure
POST /api/set_category_budget # Set category budget

# AI & Chat
POST /api/chat             # AI chat (main)
POST /api/chat_legacy      # Legacy chat
GET  /api/memory           # Get memory
POST /api/memory           # Add memory

# RAG System
POST /api/rag/add          # Add to RAG
GET  /api/rag/search       # Search RAG

# Categories & Icons
GET  /api/categories       # Get categories
GET  /api/icons            # Get icons
POST /api/activate_icon    # Activate icon

# Analytics
GET  /api/dashboard_summary # Dashboard data
GET  /api/safe_to_spend    # Safe to spend
GET  /api/category_analysis/{cat} # Category analysis
GET  /api/daily_briefing   # Daily briefing

# Goals
GET  /api/goals            # List goals
POST /api/goals            # Add goal
DELETE /api/goals/{id}     # Delete goal

# Utilities
POST /api/intent           # Intent detection
GET  /api/periods          # Get periods
GET  /api/period/{period}  # Get specific period
```

---

## 🔧 **CURSOR AI INTEGRATION GUIDE**

### **How to Add New Features**

1. **New Endpoints**: Add to `pi2_server.py` in the `api` router section
2. **New Modules**: Create separate files and import in `pi2_server.py`
3. **Database Changes**: Modify JSON structure in `states/` directory
4. **AI Features**: Extend `chat_ollama()` function or create new AI functions
5. **RAG Features**: Use `RAG_INDEX` for document operations

### **Code Patterns to Follow**

```python
# New endpoint pattern
@api.post("/new_endpoint")
async def new_endpoint(data: NewDataModel):
    try:
        # Business logic here
        result = process_data(data)
        return {"status": "ok", "data": result}
    except Exception as e:
        logger.error("Error in new_endpoint: %s", e)
        raise HTTPException(status_code=500, detail=str(e))

# New data model pattern
class NewDataModel(BaseModel):
    field1: str
    field2: Optional[int] = None
    field3: List[str] = []
```

### **Common Imports**
```python
from fastapi import FastAPI, Request, HTTPException, APIRouter, Query
from pydantic import BaseModel
from typing import Any, Dict, List, Optional
import requests
from rag_mem import RagIndex, MemoryStore
from xu_guard import is_recent_duplicate
```

---

## 🚨 **CURRENT ISSUES & IMPROVEMENTS NEEDED**

### **Critical Issues**
1. **Ollama Offline**: No fallback when Ollama returns 404
2. **Single User**: Only supports `user_id="default"`
3. **No Authentication**: Anyone can access the API
4. **No Rate Limiting**: Vulnerable to spam
5. **JSON Persistence**: Not scalable for multiple users

### **Recommended Improvements**
1. **Add Ollama Fallback**: Use local LLM or external API when Ollama offline
2. **Multi-User Support**: JWT authentication + user-specific data
3. **Database Migration**: Move from JSON to SQLite/PostgreSQL
4. **Rate Limiting**: Add request throttling
5. **Error Handling**: Better error responses and logging
6. **API Versioning**: Add `/api/v1/` prefix for future compatibility

---

## 🎯 **UNIVERSALIZATION PLAN**

### **Phase 1: Fix Current Issues**
- Add Ollama fallback
- Implement proper error handling
- Add missing endpoints (`/api/health`)

### **Phase 2: Multi-Platform Support**
- JWT authentication
- User management
- Database migration
- Rate limiting

### **Phase 3: Advanced Features**
- Real-time updates (WebSocket)
- Push notifications
- Data export/import
- Advanced analytics

### **Phase 4: External Access**
- ngrok/tunnel integration
- Cloud deployment options
- API documentation (OpenAPI)
- Monitoring and logging

---

## 📚 **QUICK REFERENCE FOR CURSOR AI**

### **File Locations**
- **Main Server**: `pi2_server.py`
- **RAG System**: `rag_mem.py`
- **Anti-Duplication**: `xu_guard.py`
- **Knowledge Base**: `financial_knowledge_base.md`
- **User Data**: `states/default.json`
- **Categories**: `categories.json`

### **Key Functions**
- **Chat**: `chat_ollama(prompt, user_id, state)`
- **RAG Search**: `RAG_INDEX.top_k(query, k)`
- **State Management**: `load_state(user_id)`, `save_state(user_id, state)`
- **Anti-Duplication**: `is_recent_duplicate(user_id, message)`

### **Common Patterns**
- All endpoints return JSON with `{"status": "ok"}` or error
- User ID is always `"default"` (single user)
- State is loaded/saved for each request
- RAG context is added to chat prompts
- All AI calls go through `chat_ollama()`

---

**Last Updated**: 2025-01-04  
**Version**: 1.0  
**Status**: Production Ready (with known issues)
