@echo off
setlocal enabledelayedexpansion
chcp 65001 >nul

cls
echo ========================================
echo    XUBUDGET - Shutdown Geral
echo ========================================
echo.

echo [STOP] Finalizando processos do stack...
for %%P in (node.exe python.exe ollama.exe "ollama app.exe") do (
  taskkill /F /IM %%P >nul 2>&1
)

echo [STOP] Liberando portas 5002 e 3000 (se houver)...
for %%P in (5002 3000) do (
  for /f "tokens=5" %%I in ('netstat -ano ^| find ":%%P " ^| find "LISTENING"') do taskkill /F /PID %%I >nul 2>&1
)

echo [STATUS] Portas apos limpeza:
for %%P in (5002 3000) do (
  netstat -ano | findstr /R /C:":%%P " | find "LISTENING" >nul
  if !errorlevel! equ 0 (
    echo   Porta %%P ainda em uso.
  ) else (
    echo   Porta %%P livre.
  )
)

echo.
echo Todos os servicos foram finalizados.
echo.
pause
endlocal