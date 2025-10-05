@echo off
echo ========================================
echo    COPIE UMA IMAGEM PARA A XUZINHA
echo ========================================
echo.
echo 1. Coloque uma imagem na area de trabalho
echo 2. Digite o nome da imagem (com extensao)
echo 3. A imagem sera copiada para o projeto
echo.
echo Formatos aceitos: .png, .jpg, .jpeg, .gif, .svg
echo.
set /p IMAGE_NAME="Digite o nome da imagem: "

if "%IMAGE_NAME%"=="" (
    echo Erro: Nome da imagem nao pode estar vazio!
    pause
    exit /b 1
)

set DESKTOP_PATH=%USERPROFILE%\Desktop\%IMAGE_NAME%
set PROJECT_PATH=public\images\xuzinha\xuzinha_avatar.png

if not exist "%DESKTOP_PATH%" (
    echo Erro: Imagem nao encontrada na area de trabalho!
    echo Caminho procurado: %DESKTOP_PATH%
    pause
    exit /b 1
)

echo.
echo Copiando imagem...
copy "%DESKTOP_PATH%" "%PROJECT_PATH%"

if %ERRORLEVEL% EQU 0 (
    echo.
    echo ========================================
    echo    SUCESSO! IMAGEM COPIADA!
    echo ========================================
    echo.
    echo Imagem copiada para: %PROJECT_PATH%
    echo.
    echo Agora a Xuzinha vai usar esta imagem como avatar!
    echo.
) else (
    echo.
    echo Erro ao copiar a imagem!
)

pause
