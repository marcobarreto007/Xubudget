@echo off
setlocal
cd /d %~dp0 || goto :err
docker compose -f docker-compose.yml -f docker-compose.https.yml down --remove-orphans
echo [OK] Proxy and API stopped.
goto :eof

:err
echo [ERRO] Falha ao parar os containers.
exit /b 1

