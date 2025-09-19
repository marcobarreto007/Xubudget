@echo off
echo Starting Xubudget FastAPI Backend Server...
cd services/pi2_assistant

echo Installing Python dependencies...
pip install -r requirements.txt

echo Starting FastAPI server on port 5001...
python -m uvicorn pi2_server:app --host 0.0.0.0 --port 5001 --reload

pause