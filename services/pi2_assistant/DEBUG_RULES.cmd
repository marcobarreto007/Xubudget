@echo off
setlocal

REM Quick debug for AI rules endpoints and flow
REM 1) ensure data folder
set "ROOT=%~dp0"
cd /d "%ROOT%" || goto :err
if not exist "%ROOT%data" mkdir "%ROOT%data"

REM 2) start/restart API in a new window (localhost:5002)
echo [API] Starting (or reloading) server...
start "Xubudget API" cmd /k "cd /d %ROOT% && START_API.cmd"

REM Wait a bit for the API to be up
timeout /t 3 >nul 2>&1

set "BASE=http://127.0.0.1:5002"
echo [CHECK] Health: %BASE%/api/healthz
curl -s %BASE%/api/healthz
echo.

REM 3) learn rule manually
echo [LEARN] merchant=uber -> category=transporte
curl -s -X POST %BASE%/api/ai/learn_merchant_category -H "Content-Type: application/json" ^
  -d "{\"merchant\":\"uber\",\"category\":\"transporte\"}"
echo.

REM 4) add expense without category (merchant=Uber) -> should classify transporte
echo [ADD] expense amount=-25.9, merchant=Uber (no category)
curl -s -X POST %BASE%/api/add_expense -H "Content-Type: application/json" ^
  -d "{\"amount\":25.9,\"merchant\":\"Uber\"}"
echo.

REM 5) reclassify with learning (index 1-based = most recent)
echo [RECLASSIFY] expense_id=1 -> restaurantes (learn=true)
curl -s -X POST "%BASE%/api/expense/reclassify?learn=true" -H "Content-Type: application/json" ^
  -d "{\"expense_id\":1,\"new_category\":\"restaurantes\"}"
echo.

echo Done. You can also GET rules at: %BASE%/api/ai/rules
goto :eof

:err
echo [ERRO] Falha ao executar script.
pause

