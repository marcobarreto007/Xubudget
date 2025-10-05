@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - SISTEMA COMPLETO

cls
echo ========================================
echo    XUBUDGET - SISTEMA COMPLETO
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
echo [3/3] Iniciando Xubudget Completo...
echo [INFO] Sistema com IA, OCR, RAG e Chat
start "Xubudget Completo" cmd /k "python pi2_server.py"

echo.
echo ========================================
echo   XUBUDGET COMPLETO RODANDO!
echo   URL: http://localhost:3000
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
echo [INFO] Sistema completo com todas as funcionalidades
echo.
timeout /t 3 /nobreak >nul
start http://localhost:3000
pause
endlocal
