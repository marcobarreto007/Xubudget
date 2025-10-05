@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - SISTEMA ORIGINAL

cls
echo ========================================
echo    XUBUDGET - SISTEMA ORIGINAL
echo    IA + OCR + RAG + CHAT
echo ========================================
echo.

echo [1/3] Verificando dependencias...
python --version >nul 2>&1 || (echo [ERRO] Python nao encontrado! & pause & exit /b 1)
echo [OK] Python encontrado!

echo.
echo [2/3] Verificando Ollama (IA Local)...
curl -s http://127.0.0.1:11434/api/tags >nul 2>&1
if errorlevel 1 (
    echo [INFO] Ollama nao detectado. Iniciando servidor...
    start "Ollama" cmd /k "ollama serve"
    timeout /t 3 /nobreak >nul
) else (
    echo [OK] Ollama ativo.
)

echo.
echo [3/3] Iniciando Xubudget Original...
echo [INFO] Sistema completo com IA, OCR, RAG e Chat
start "Xubudget Original" cmd /k "python pi2_server.py"

echo.
echo ========================================
echo   XUBUDGET ORIGINAL RODANDO!
echo   URL: http://localhost:5002
echo ========================================
echo.
echo [FEATURES]
echo - IA Xuzinha (Chat inteligente)
echo - OCR para fotos de recibos
echo - RAG (Retrieval Augmented Generation)
echo - Categorizacao automatica
echo - Dashboard financeiro
echo.
echo [INFO] O navegador abrira automaticamente
echo [INFO] Sistema original funcionando
echo.
timeout /t 3 /nobreak >nul
start http://localhost:5002
pause
endlocal
