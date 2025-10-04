@echo off
setlocal
REM Quick smoke tests against HTTPS proxy (localhost)

set BASE=https://localhost
echo [CHECK] Proxy health
curl -ks %BASE%/proxy-healthz || goto :err
echo.

echo [CHECK] API health
curl -ks %BASE%/api/healthz || goto :err
echo.

echo [CHECK] Safe-to-spend
curl -ks %BASE%/api/safe_to_spend || goto :err
echo.

echo [CHECK] Timeline
curl -ks %BASE%/api/timeline || goto :err
echo.

echo [CHECK] Daily briefing
curl -ks %BASE%/api/daily_briefing || goto :err
echo.

echo [OK] Proxy and API responding over HTTPS.
goto :eof

:err
echo [FAIL] Smoke test failed.
exit /b 1

