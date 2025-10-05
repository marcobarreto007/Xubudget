@echo off
setlocal
echo Starting Xubudget FastAPI Backend Server on port 5001...

REM Navigate to project root
cd /d "C:\Users\marco\Xubudget\Xubudget"

echo Installing Python dependencies...
pip install -r services\pi2_assistant\requirements.txt

echo Setting PYTHONPATH to project root...
set PYTHONPATH=%CD%

echo Starting FastAPI server on http://127.0.0.1:5001 (reload enabled)...
python -m uvicorn services.pi2_assistant.pi2_server:app --host 127.0.0.1 --port 5001 --reload

endlocal
pause