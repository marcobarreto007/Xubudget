@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

title XUBUDGET - Launcher

cls
echo ========================================
echo    XUBUDGET - Iniciando Sistema
echo ========================================
echo.

echo [CHK] Verificando dependencias...
python --version >nul 2>&1 || (echo [ERRO] Python nao encontrado & pause & exit /b 1)
node --version >nul 2>&1   || (echo [ERRO] Node.js nao encontrado & pause & exit /b 1)
echo [OK] Python e Node encontrados.

echo.
echo [CHK] Verificando Ollama (IA local)...
curl -s http://127.0.0.1:11434/api/tags >nul 2>&1
if errorlevel 1 (
    where ollama >nul 2>&1 || (echo [ERRO] Ollama nao encontrado no PATH. Instale ou ajuste as variaveis de ambiente. & pause & exit /b 1)
    echo [INFO] Ollama nao detectado. Inicializando servidor...
    start "Ollama" cmd /k "ollama serve"
    timeout /t 3 >nul
) else (
    echo [OK] Ollama ativo.
)

for /f "delims=" %%A in ('curl -s http://127.0.0.1:11434/api/tags ^| findstr /i "qwen2.5:1.5b-instruct"') do set "OLLAMA_HAVE_QWEN=1"
if not defined OLLAMA_HAVE_QWEN (
    echo [SETUP] Baixando modelo qwen2.5:1.5b-instruct para o chat...
    where ollama >nul 2>&1 && ollama pull qwen2.5:1.5b-instruct
)

echo.
set "ROOT_DIR=%~dp0"
set "ROOT_DIR=%ROOT_DIR:~0,-1%"
cd /d "%ROOT_DIR%" || (echo [ERRO] Falha ao acessar %ROOT_DIR% & pause & exit /b 1)

REM --- Preparar ambiente Python -------------------------------------------------
if not exist ".venv\Scripts\python.exe" (
    echo [SETUP] Criando ambiente virtual Python...
    py -3 -m venv .venv || (echo [ERRO] Falha ao criar venv & pause & exit /b 1)
    echo [SETUP] Instalando dependencias backend...
    call .venv\Scripts\python.exe -m pip install -U pip >nul || (echo [ERRO] Falha atualizando pip & pause & exit /b 1)
    if exist requirements.txt (
        call .venv\Scripts\python.exe -m pip install -r requirements.txt || (echo [ERRO] Falha instalando requirements.txt & pause & exit /b 1)
    ) else (
        call .venv\Scripts\python.exe -m pip install fastapi uvicorn[standard] python-multipart || (echo [ERRO] Falha instalando deps minimos & pause & exit /b 1)
    )
) else (
    call .venv\Scripts\python.exe -m pip install -q -U pip >nul 2>&1
)

REM Garantir python-multipart (uploads)
call .venv\Scripts\python.exe -c "import multipart" >nul 2>&1 || (
    echo [SETUP] Instalando python-multipart...
    call .venv\Scripts\pip.exe install python-multipart >nul || (echo [ERRO] Falha instalando python-multipart & pause & exit /b 1)
)

echo.
echo [START] Backend (porta 5002)...
set "USE_OLLAMA=1"
set "OLLAMA_HOST=http://127.0.0.1:11434"
set "OLLAMA_MODEL=qwen2.5:1.5b-instruct"
start "Xubudget Backend" cmd /k ".venv\Scripts\python.exe -m uvicorn pi2_server:app --host 0.0.0.0 --port 5002 --reload"
timeout /t 5 /nobreak >nul

echo [START] Frontend (porta 3000)...
pushd new_frontend || (echo [ERRO] Pasta new_frontend nao encontrada & pause & exit /b 1)
if not exist "node_modules" (
    echo [SETUP] Instalando dependencias npm...
    call npm install || (echo [ERRO] npm install falhou & popd & pause & exit /b 1)
)
set "REACT_APP_API_BASE=http://127.0.0.1:5002"
start "Xubudget Frontend" cmd /k "npm start"
popd

timeout /t 5 /nobreak >nul
start http://localhost:3000

echo.
echo ========================================
echo   XUBUDGET RODANDO
echo   Backend:  http://127.0.0.1:5002
echo   Frontend: http://localhost:3000
echo ========================================
echo.
pause
endlocal

