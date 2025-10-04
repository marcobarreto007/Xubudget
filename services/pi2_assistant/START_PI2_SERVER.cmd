@echo off
echo Starting Pi2 Server (English version)...
cd /d C:\Users\marco\Xubudget\Xubudget\services\pi2_assistant
.venv\Scripts\python.exe -m uvicorn pi2_server:app --host 127.0.0.1 --port 5002 --reload
pause
