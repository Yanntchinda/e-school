@echo off
title e-School - Gestion des bulletins scolaires
echo.
echo ====================================================
echo    e-School - Lancement de l'application
echo ====================================================
echo.
echo Demarrage du serveur local...
echo L'application va s'ouvrir automatiquement dans votre navigateur.
echo Laissez cette fenetre ouverte pendant l'utilisation.
echo Pour fermer l'application, fermez cette fenetre.
echo.

start "" "http://localhost:8765/e-school.html"
cd /d "%~dp0"

if exist "%~dp0pythonw.exe" (
    start /b "" "%~dp0pythonw.exe" -m http.server 8765
) else (
    where python >nul 2>&1
    if %errorlevel% equ 0 (
        start /b python -m http.server 8765
    ) else (
        echo ERREUR : Python n'est pas installe sur votre ordinateur.
        echo Telechargez Python sur https://www.python.org/ et cochez "Add Python to PATH" pendant l'installation.
        echo.
        pause
        exit /b
    )
)

:loop
timeout /t 2 >nul
tasklist /fi "imagename eq chrome.exe" /fi "windowtitle eq e-School*" 2>nul | find ":" >nul
goto loop
