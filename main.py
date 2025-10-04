"""
Xubudget API - FastAPI Backend
API for Brazilian expense categorization
"""

from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Dict, Any, List
import logging
import uvicorn

from categorizer import categorizer
from database import db_service
from receipt_scanner import ReceiptScanner

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Create FastAPI app
app = FastAPI(
    title="Xubudget API",
    description="API for Brazilian expense categorization using AI",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

# Configure CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # In production, specify allowed domains
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Pydantic models
class CategorizeRequest(BaseModel):
    text: str

class CategorizeResponse(BaseModel):
    category: str
    confidence: float

class HealthResponse(BaseModel):
    status: str
    service: str
    version: str

class ExpenseRequest(BaseModel):
    description: str
    amount: float
    category: str
    date: str = None

class ExpenseResponse(BaseModel):
    id: int
    description: str
    amount: float
    category: str
    date: str
    created_at: str

class CategorySummaryResponse(BaseModel):
    categories: list
    total_amount: float
    total_count: int
    recent_expense: dict = None

class ReceiptScanRequest(BaseModel):
    text: str

class ReceiptScanResponse(BaseModel):
    success: bool
    data: dict = None
    error: str = None
    confidence: float = 0.0

# Endpoints
@app.get("/api/health", response_model=HealthResponse)
async def health_check():
    """
    Health check endpoint
    """
    return HealthResponse(
        status="healthy",
        service="xubudget-api",
        version="1.0.0"
    )

@app.post("/api/categorize", response_model=CategorizeResponse)
async def categorize_expense(request: CategorizeRequest):
    """
    Categorizes an expense using AI
    
    Args:
        request: CategorizeRequest with expense text
        
    Returns:
        CategorizeResponse with category and confidence
    """
    try:
        if not request.text or not request.text.strip():
            raise HTTPException(
                status_code=400,
                detail="Text cannot be empty"
            )
        
        logger.info(f"Categorizing expense: '{request.text}'")
        result = categorizer.categorize_expense(request.text.strip())
        
        return CategorizeResponse(**result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Internal error in categorization: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

# Additional endpoint to test Ollama connectivity
@app.get("/api/ollama-status")
async def ollama_status():
    """
    Checks Ollama connection status
    """
    try:
        import requests
        response = requests.get("http://localhost:11434/api/tags", timeout=5)
        if response.status_code == 200:
            return {
                "status": "connected",
                "ollama_url": "http://localhost:11434",
                "models": response.json().get("models", [])
            }
        else:
            return {
                "status": "error",
                "message": f"Ollama returned status {response.status_code}"
            }
    except Exception as e:
        return {
            "status": "disconnected",
            "message": f"Error connecting to Ollama: {str(e)}"
        }

@app.post("/api/scan-receipt", response_model=ReceiptScanResponse)
async def scan_receipt(request: ReceiptScanRequest):
    """
    Scans receipt text and extracts expense data
    
    Args:
        request: ReceiptScanRequest with receipt text
        
    Returns:
        ReceiptScanResponse with extracted data and confidence
    """
    try:
        if not request.text or not request.text.strip():
            raise HTTPException(
                status_code=400,
                detail="Receipt text cannot be empty"
            )
        
        logger.info("Scanning receipt...")
        scanner = ReceiptScanner()
        result = scanner.scan_receipt(request.text.strip())
        
        return ReceiptScanResponse(**result)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Internal error scanning receipt: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

# ===== EXPENSE ENDPOINTS =====

@app.post("/api/expenses", response_model=ExpenseResponse)
async def add_expense(request: ExpenseRequest):
    """
    Adds a new expense
    
    Args:
        request: Expense data (description, amount, category, date)
        
    Returns:
        ExpenseResponse: Created expense data
    """
    try:
        # Validate input
        if not request.description or not request.description.strip():
            raise HTTPException(
                status_code=400, 
                detail="Expense description cannot be empty"
            )
        
        if request.amount <= 0:
            raise HTTPException(
                status_code=400, 
                detail="Expense amount must be greater than zero"
            )
        
        if not request.category or not request.category.strip():
            raise HTTPException(
                status_code=400, 
                detail="Expense category cannot be empty"
            )
        
        # Add expense to database
        logger.info(f"Adding expense: {request.description}, R$ {request.amount}")
        expense = db_service.add_expense(
            description=request.description.strip(),
            amount=request.amount,
            category=request.category.strip(),
            date=request.date
        )
        
        return ExpenseResponse(**expense)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Internal error adding expense: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

@app.get("/api/expenses", response_model=List[ExpenseResponse])
async def get_expenses(days: int = None, limit: int = None):
    """
    Retrieves expenses from database
    
    Args:
        days: Number of days to filter (optional)
        limit: Record limit (optional)
        
    Returns:
        List of expenses
    """
    try:
        logger.info(f"Retrieving expenses: days={days}, limit={limit}")
        expenses = db_service.get_expenses(days=days, limit=limit)
        
        return [ExpenseResponse(**expense) for expense in expenses]
        
    except Exception as e:
        logger.error(f"Internal error retrieving expenses: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

@app.get("/api/expenses/by-category", response_model=List[ExpenseResponse])
async def get_expenses_by_category(category: str = None):
    """
    Retrieves expenses grouped by category
    
    Args:
        category: Specific category (optional)
        
    Returns:
        List of expenses grouped by category
    """
    try:
        logger.info(f"Retrieving expenses by category: {category}")
        expenses = db_service.get_by_category(category=category)
        
        return [ExpenseResponse(**expense) for expense in expenses]
        
    except Exception as e:
        logger.error(f"Internal error retrieving expenses by category: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

@app.get("/api/expenses/summary", response_model=CategorySummaryResponse)
async def get_expenses_summary():
    """
    Returns expense summary by category
    
    Returns:
        Summary with totals by category and statistics
    """
    try:
        logger.info("Generating expense summary")
        summary = db_service.get_category_summary()
        
        return CategorySummaryResponse(**summary)
        
    except Exception as e:
        logger.error(f"Internal error generating summary: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

@app.delete("/api/expenses/{expense_id}")
async def delete_expense(expense_id: int):
    """
    Removes an expense
    
    Args:
        expense_id: ID of expense to remove
        
    Returns:
        Removal confirmation
    """
    try:
        logger.info(f"Removing expense ID: {expense_id}")
        deleted = db_service.delete_expense(expense_id)
        
        if deleted:
            return {"message": f"Expense {expense_id} removed successfully"}
        else:
            raise HTTPException(
                status_code=404,
                detail=f"Expense {expense_id} not found"
            )
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Internal error removing expense: {e}")
        raise HTTPException(
            status_code=500,
            detail="Internal server error"
        )

# Root endpoint
@app.get("/")
async def root():
    """
    Root endpoint with API information
    """
    return {
        "message": "Xubudget API - Expense Categorization",
        "version": "1.0.0",
        "endpoints": {
            "health": "/api/health",
            "categorize": "/api/categorize",
            "scan_receipt": "/api/scan-receipt",
            "ollama_status": "/api/ollama-status",
            "add_expense": "/api/expenses",
            "get_expenses": "/api/expenses",
            "get_by_category": "/api/expenses/by-category",
            "get_summary": "/api/expenses/summary",
            "delete_expense": "/api/expenses/{id}",
            "docs": "/docs"
        }
    }

if __name__ == "__main__":
    # Run server
    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=5003,
        reload=True,
        log_level="info"
    )