@echo off
setlocal
title GestSchool
cd /d "%~dp0"
set PORT=8765

echo.
echo ==========================================================
echo    GestSchool
echo ==========================================================
echo.
echo Demarrage du serveur local, puis ouverture de l'application.
echo Gardez cette fenetre ouverte pendant l'utilisation.
echo Pour fermer : fermez cette fenetre, ou lancez ARRETER-GESTSCHOOL.bat
echo.

rem ---------- Recherche d'un moteur Python ----------
set ENGINE=
if exist "%~dp0pythonw.exe" set ENGINE=EMBEDDED
if defined ENGINE goto START
where python >nul 2>&1
if not errorlevel 1 set ENGINE=PYTHON
if defined ENGINE goto START
where py >nul 2>&1
if not errorlevel 1 set ENGINE=PY
if defined ENGINE goto START
goto NOPYTHON

rem ---------- Demarrage du serveur ----------
:START
echo Moteur detecte : %ENGINE%
if "%ENGINE%"=="EMBEDDED" start /b "" "%~dp0pythonw.exe" -m http.server %PORT%
if "%ENGINE%"=="PYTHON"   start /b python -m http.server %PORT%
if "%ENGINE%"=="PY"       start /b py -3 -m http.server %PORT%

echo Ouverture de l'application dans le navigateur...
timeout /t 3 >nul
start "" "http://localhost:%PORT%/GestSchool.html"
goto LOOP

rem ---------- Attente ----------
:LOOP
timeout /t 5 >nul
goto LOOP

rem ---------- Python absent ----------
:NOPYTHON
echo.
echo ERREUR : Python n'a pas ete trouve sur cet ordinateur.
echo.
echo Deux solutions :
echo   1. Installer Python : https://www.python.org
echo      IMPORTANT : cochez "Add Python to PATH" pendant l'installation.
echo.
echo   2. Sans rien installer : double-cliquez sur le fichier GestSchool.html
echo      situe dans ce meme dossier. Il s'ouvre directement dans le navigateur.
echo.
pause
exit /b 1
