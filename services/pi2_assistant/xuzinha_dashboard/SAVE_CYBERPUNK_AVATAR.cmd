@echo off
echo ========================================
echo    SALVAR AVATAR CYBERPUNK DA XUZINHA
echo ========================================
echo.
echo 1. Salve a imagem cyberpunk na area de trabalho
echo 2. Nomeie como: xuzinha_cyberpunk.png
echo 3. Execute este script para copiar automaticamente
echo.
echo Formatos aceitos: .png, .jpg, .jpeg, .gif, .svg
echo.

set IMAGE_NAME=xuzinha_cyberpunk.png
set DESKTOP_PATH=%USERPROFILE%\Desktop\%IMAGE_NAME%
set PROJECT_PATH=public\images\xuzinha\xuzinha_avatar.png

if not exist "%DESKTOP_PATH%" (
    echo ========================================
    echo    INSTRUCOES:
    echo ========================================
    echo.
    echo 1. Salve a imagem cyberpunk na area de trabalho
    echo 2. Nomeie como: xuzinha_cyberpunk.png
    echo 3. Execute este script novamente
    echo.
    echo Caminho esperado: %DESKTOP_PATH%
    echo.
    pause
    exit /b 1
)

echo.
echo Encontrei a imagem! Copiando...
copy "%DESKTOP_PATH%" "%PROJECT_PATH%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo    SUCESSO! AVATAR CYBERPUNK SALVO!
    echo ========================================
    echo.
    echo A Xuzinha agora tem o avatar cyberpunk!
    echo.
    echo Imagem copiada para: %PROJECT_PATH%
    echo.
    echo Recarregue a pagina para ver o novo avatar!
    echo.
) else (
    echo.
    echo Erro ao copiar a imagem!
)

pause
