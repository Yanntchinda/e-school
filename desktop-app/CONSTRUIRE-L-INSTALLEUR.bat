@echo off
setlocal enabledelayedexpansion
title e-School - Construction de l'installateur Windows
cd /d "%~dp0"

echo.
echo ==========================================================
echo    e-School - Construction de l'installateur Windows
echo ==========================================================
echo.

REM ---------- 1. Verification de Node.js ----------
where node >nul 2>&1
if errorlevel 1 (
    echo [ERREUR] Node.js n'est pas installe sur cet ordinateur.
    echo.
    echo Telechargez-le ici : https://nodejs.org
    echo Prenez la version "LTS", installez-la en laissant toutes
    echo les options par defaut, puis relancez ce fichier.
    echo.
    pause
    exit /b 1
)

for /f "tokens=*" %%v in ('node -v') do set NODEVER=%%v
echo [OK] Node.js !NODEVER! detecte.
echo.

REM ---------- 2. Installation des dependances ----------
if not exist "node_modules" (
    echo [1/2] Installation des composants ^(environ 3 a 8 minutes^)...
    echo       Une connexion internet est necessaire la premiere fois.
    echo.
    call npm install --no-audit --no-fund
    if errorlevel 1 (
        echo.
        echo [ERREUR] L'installation a echoue. Verifiez votre connexion internet.
        pause
        exit /b 1
    )
) else (
    echo [1/2] Composants deja installes.
)
echo.

REM ---------- 3. Construction ----------
echo [2/2] Construction de l'installateur ^(environ 2 a 5 minutes^)...
echo.
call npm run build:win
if errorlevel 1 (
    echo.
    echo [ERREUR] La construction a echoue. Lisez le message ci-dessus.
    pause
    exit /b 1
)

echo.
echo ==========================================================
echo    TERMINE
echo ==========================================================
if exist "dist\installers" (
    echo L'installateur se trouve dans :
    echo    %~dp0dist\installers
    echo.
    start "" "%~dp0dist\installers"
) else (
    echo Le dossier dist\installers n'a pas ete cree : lisez le message ci-dessus.
)
echo.
pause
endlocal
