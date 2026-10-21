@echo off
title e-School - Mise a jour de l'application
cd /d "%~dp0"

set SOURCE=..\e-school\e-school\index.html

if not exist "%SOURCE%" (
    echo [ERREUR] Fichier introuvable : %SOURCE%
    echo Ce script doit rester dans le dossier desktop-app du projet e-school.
    pause
    exit /b 1
)

copy /y "%SOURCE%" "app\index.html" >nul
if errorlevel 1 (
    echo [ERREUR] La copie a echoue.
    pause
    exit /b 1
)

echo [OK] Le logiciel a ete mis a jour dans app\index.html
echo.
echo Relancez la construction de l'installateur pour diffuser la nouvelle version :
echo     CONSTRUIRE-L-INSTALLEUR.bat
echo.
pause
