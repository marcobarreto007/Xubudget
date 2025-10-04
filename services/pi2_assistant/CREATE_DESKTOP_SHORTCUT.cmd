@echo off
setlocal ENABLEDELAYEDEXPANSION

REM =============================================================================
REM CRIAR ATALHO DO XUBUDGET NA ÁREA DE TRABALHO
REM =============================================================================

echo.
echo 🦉 CRIANDO ATALHO DO XUBUDGET NA ÁREA DE TRABALHO 🦉
echo ===================================================
echo.

REM --- Configurações ---
set SCRIPT_PATH=%~dp0START_XUBUDGET.cmd
set DESKTOP=%USERPROFILE%\Desktop
set SHORTCUT_NAME=Xubudget - Iniciar Sistema
set SHORTCUT_PATH=%DESKTOP%\%SHORTCUT_NAME%.lnk

REM --- Verificar se o script existe ---
if not exist "%SCRIPT_PATH%" (
    echo ❌ ERRO: Script START_XUBUDGET.cmd não encontrado!
    echo    Certifique-se de que este arquivo está na mesma pasta.
    pause
    exit /b 1
)

echo ✅ Script encontrado: %SCRIPT_PATH%

REM --- Criar atalho usando PowerShell ---
echo 🔗 Criando atalho na área de trabalho...

powershell -Command "& {$WshShell = New-Object -comObject WScript.Shell; $Shortcut = $WshShell.CreateShortcut('%SHORTCUT_PATH%'); $Shortcut.TargetPath = '%SCRIPT_PATH%'; $Shortcut.WorkingDirectory = '%~dp0'; $Shortcut.Description = 'Xubudget - Sistema Completo de Controle Financeiro'; $Shortcut.IconLocation = 'shell32.dll,137'; $Shortcut.Save()}"

if exist "%SHORTCUT_PATH%" (
    echo ✅ Atalho criado com sucesso!
    echo    Localização: %SHORTCUT_PATH%
    echo.
    echo 🎯 Agora você pode:
    echo    - Clicar duas vezes no ícone "Xubudget - Iniciar Sistema" na área de trabalho
    echo    - O sistema irá iniciar automaticamente todos os serviços
    echo    - API, Frontend, IA Local e Mobile App estarão disponíveis
    echo.
    
    REM --- Perguntar se quer executar agora ---
    set /p choice="Deseja executar o Xubudget agora? (s/n): "
    if /i "!choice!"=="s" (
        echo.
        echo 🚀 Executando Xubudget...
        call "%SCRIPT_PATH%"
    ) else (
        echo.
        echo ✅ Pronto! Use o atalho na área de trabalho quando quiser iniciar o Xubudget.
    )
) else (
    echo ❌ ERRO: Falha ao criar o atalho!
    echo    Tentando método alternativo...
    
    REM --- Método alternativo usando VBScript ---
    echo Set oWS = WScript.CreateObject("WScript.Shell") > "%TEMP%\CreateShortcut.vbs"
    echo sLinkFile = "%SHORTCUT_PATH%" >> "%TEMP%\CreateShortcut.vbs"
    echo Set oLink = oWS.CreateShortcut(sLinkFile) >> "%TEMP%\CreateShortcut.vbs"
    echo oLink.TargetPath = "%SCRIPT_PATH%" >> "%TEMP%\CreateShortcut.vbs"
    echo oLink.WorkingDirectory = "%~dp0" >> "%TEMP%\CreateShortcut.vbs"
    echo oLink.Description = "Xubudget - Sistema Completo de Controle Financeiro" >> "%TEMP%\CreateShortcut.vbs"
    echo oLink.IconLocation = "shell32.dll,137" >> "%TEMP%\CreateShortcut.vbs"
    echo oLink.Save >> "%TEMP%\CreateShortcut.vbs"
    
    cscript //nologo "%TEMP%\CreateShortcut.vbs"
    del "%TEMP%\CreateShortcut.vbs"
    
    if exist "%SHORTCUT_PATH%" (
        echo ✅ Atalho criado com sucesso (método alternativo)!
    ) else (
        echo ❌ Falha ao criar atalho. Tente executar como administrador.
    )
)

echo.
echo Pressione qualquer tecla para fechar...
pause >nul


