@echo off
set SCRIPT_PATH=%~dp0START_XUBUDGET.cmd
set DESKTOP=%USERPROFILE%\Desktop
set SHORTCUT_NAME=Xubudget - Iniciar Sistema (Novo)
set SHORTCUT_PATH=%DESKTOP%\%SHORTCUT_NAME%.lnk

echo Set oWS = WScript.CreateObject("WScript.Shell") > CreateShortcut.vbs
echo sLinkFile = "%SHORTCUT_PATH%" >> CreateShortcut.vbs
echo Set oLink = oWS.CreateShortcut(sLinkFile) >> CreateShortcut.vbs
echo oLink.TargetPath = "%SCRIPT_PATH%" >> CreateShortcut.vbs
echo oLink.WorkingDirectory = "%~dp0" >> CreateShortcut.vbs
echo oLink.Save >> CreateShortcut.vbs

cscript //nologo CreateShortcut.vbs
del CreateShortcut.vbs
