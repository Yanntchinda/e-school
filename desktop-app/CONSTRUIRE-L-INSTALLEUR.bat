@echo off
setlocal enabledelayedexpansion
title GestSchool - Construction de l'installateur Windows
cd /d "%~dp0"

echo.
echo ==========================================================
echo    GestSchool - Construction de l'installateur Windows
echo ==========================================================
echo.
echo Ce script fabrique deux fichiers .exe : installateur et portable.
echo Duree : 5 a 12 minutes la premiere fois.
echo.

rem ---------- 1. Node.js ----------
where node >nul 2>&1
if errorlevel 1 goto NONODE
where npm >nul 2>&1
if errorlevel 1 goto NONODE

for /f "tokens=*" %%v in ('node -v') do set "NODEVER=%%v"
echo [OK] Node.js !NODEVER! detecte.
echo.

rem ---------- 2. Fichiers du programme ----------
if not exist "app\index.html" goto NOAPP
if not exist "main.js" goto NOAPP
if not exist "app\icon.ico" goto NOAPP
echo [OK] Fichiers du programme presents.
echo.

rem ---------- 3. Composants ----------
if exist "node_modules\electron-builder" goto HASDEPS

echo [1/2] Telechargement des composants : environ 150 Mo.
echo       Une connexion internet est necessaire.
echo       Patientez, l'affichage peut rester fige plusieurs minutes.
echo.
call npm install --no-audit --no-fund
if errorlevel 1 goto DEPFAIL
echo.
echo [OK] Composants installes.
echo.
goto BUILD

:HASDEPS
echo [1/2] Composants deja installes.
echo.

rem ---------- 4. Fabrication ----------
:BUILD
echo [2/2] Fabrication de l'installateur...
echo.
call npm run build:win
if errorlevel 1 goto BUILDFAIL

echo.
echo ==========================================================
echo    TERMINE
echo ==========================================================
if not exist "dist\installers\*.exe" goto NOEXE

echo.
echo Vos fichiers .exe sont prets :
echo.
for %%f in ("dist\installers\*.exe") do echo    %%~nxf
echo.
echo Dossier :
echo    %~dp0dist\installers
echo.
echo Double-cliquez sur le Setup pour installer, ou lancez le Portable
echo sans rien installer (cle USB, poste partage).
echo.
start "" "%~dp0dist\installers"
pause
exit /b 0

rem ---------- Erreurs ----------
:NONODE
echo.
echo [ERREUR] Node.js n'est pas installe.
echo.
echo   1. Ouvrez https://nodejs.org
echo   2. Cliquez sur le bouton vert "LTS"
echo   3. Installez en laissant toutes les options par defaut
echo   4. Redemarrez cet ordinateur
echo   5. Relancez ce fichier
echo.
pause
exit /b 1

:NOAPP
echo.
echo [ERREUR] Fichiers du programme manquants.
echo.
echo Ce script doit rester dans le dossier "desktop-app".
echo Les fichiers app\index.html, main.js et app\icon.ico
echo doivent se trouver a cote de lui.
echo.
pause
exit /b 1

:DEPFAIL
echo.
echo [ERREUR] Le telechargement des composants a echoue.
echo.
echo Causes les plus frequentes :
echo   - pas de connexion internet
echo   - antivirus ou pare-feu qui bloque npm
echo   - proxy d'entreprise
echo.
echo Solutions :
echo   1. Verifiez votre connexion internet
echo   2. Desactivez temporairement l'antivirus, puis relancez
echo   3. Si vous etes sur un reseau d'entreprise, demandez le proxy
echo.
echo Detail technique : voir le fichier npm-debug.log du dossier.
echo.
pause
exit /b 1

:BUILDFAIL
echo.
echo [ERREUR] La fabrication de l'installateur a echoue.
echo.
echo Solutions a essayer dans cet ordre :
echo   1. Deplacer le dossier dans C:\GestSchool\ puis relancer
echo      car les accents et les espaces dans le chemin posent probleme
echo   2. Clic droit sur ce fichier puis "Executer en tant qu'administrateur"
echo   3. Supprimer le dossier node_modules puis relancer
echo.
echo Remontez les 15 dernieres lignes affichees a votre assistance.
echo.
pause
exit /b 1

:NOEXE
echo.
echo [ERREUR] La compilation s'est terminee mais aucun .exe n'a ete produit.
echo.
echo Verifiez le dossier dist\installers.
echo.
pause
exit /b 1
