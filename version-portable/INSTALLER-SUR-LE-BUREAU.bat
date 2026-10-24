@echo off
setlocal enabledelayedexpansion
title e-School - Installation du raccourci sur le Bureau
cd /d "%~dp0"

echo.
echo ==========================================================
echo    e-School - Raccourci sur le Bureau
echo ==========================================================
echo.
echo Ce script installe une icone e-School sur votre Bureau.
echo Aucune installation, aucun outil a telecharger.
echo.

if not exist "%~dp0e-school.html" (
    echo [ERREUR] Le fichier e-school.html est introuvable.
    echo Gardez ce script dans le meme dossier que e-school.html.
    echo.
    pause
    exit /b 1
)

rem ---------- Adresse du logiciel ----------
set "APPURL=%~dp0e-school.html"
set "APPURL=%APPURL:\=/%"

rem ---------- Recherche du navigateur ----------
set "BROWSER="
for %%P in (
 "%ProgramFiles%\Google\Chrome\Application\chrome.exe"
 "%ProgramFiles(x86)%\Google\Chrome\Application\chrome.exe"
 "%LocalAppData%\Google\Chrome\Application\chrome.exe"
 "%ProgramFiles(x86)%\Microsoft\Edge\Application\msedge.exe"
 "%ProgramFiles%\Microsoft\Edge\Application\msedge.exe"
) do (
    if not defined BROWSER if exist "%%~P" set "BROWSER=%%~P"
)

if not defined BROWSER goto NOBROWSER
echo [OK] Navigateur detecte : !BROWSER!
echo.

rem ---------- Creation du raccourci ----------
set "VBSFILE=%TEMP%\eschool_shortcut.vbs"

echo Set oWS = WScript.CreateObject("WScript.Shell")> "%VBSFILE%"
echo sDesk = oWS.SpecialFolders("Desktop")>> "%VBSFILE%"
echo Set oLink = oWS.CreateShortcut(sDesk ^& "\e-School Bulletins.lnk")>> "%VBSFILE%"
echo oLink.TargetPath = "!BROWSER!">> "%VBSFILE%"
echo oLink.Arguments = "--app=""file:///%APPURL%"" --window-size=1400,900">> "%VBSFILE%"
echo oLink.WorkingDirectory = "%~dp0">> "%VBSFILE%"
echo oLink.IconLocation = "%~dp0icon.ico">> "%VBSFILE%"
echo oLink.Description = "e-School - Gestion des bulletins">> "%VBSFILE%"
echo oLink.Save>> "%VBSFILE%"
echo WScript.Quit 0>> "%VBSFILE%"

cscript //nologo "%VBSFILE%"
if errorlevel 1 goto VBSFAIL
del "%VBSFILE%" >nul 2>&1

echo ==========================================================
echo    TERMINE
echo ==========================================================
echo.
echo Une icone "e-School Bulletins" est maintenant sur votre Bureau.
echo Double-cliquez dessus pour ouvrir l'application.
echo.
echo L'application s'ouvre dans une fenetre propre, sans barre
echo d'adresse, comme un logiciel classique.
echo.
echo IMPORTANT - vos donnees :
echo elles restent dans ce dossier. Deplacez le dossier entier,
echo pas seulement le raccourci. Faites regulierement une
echo sauvegarde depuis Parametres ^> Exporter une sauvegarde.
echo.
pause
exit /b 0

:NOBROWSER
echo [ATTENTION] Ni Chrome ni Edge n'a ete trouve.
echo.
echo Un raccourci simple va etre cree : il ouvrira le logiciel
echo dans votre navigateur par defaut.
echo.

echo Set oWS = WScript.CreateObject("WScript.Shell")> "%VBSFILE%"
echo sDesk = oWS.SpecialFolders("Desktop")>> "%VBSFILE%"
echo Set oLink = oWS.CreateShortcut(sDesk ^& "\e-School Bulletins.lnk")>> "%VBSFILE%"
echo oLink.TargetPath = "%~dp0e-school.html">> "%VBSFILE%"
echo oLink.WorkingDirectory = "%~dp0">> "%VBSFILE%"
echo oLink.IconLocation = "%~dp0icon.ico">> "%VBSFILE%"
echo oLink.Description = "e-School - Gestion des bulletins">> "%VBSFILE%"
echo oLink.Save>> "%VBSFILE%"
echo WScript.Quit 0>> "%VBSFILE%"

cscript //nologo "%VBSFILE%"
del "%VBSFILE%" >nul 2>&1
echo Raccourci cree sur le Bureau.
echo.
pause
exit /b 0

:VBSFAIL
del "%VBSFILE%" >nul 2>&1
echo.
echo [ERREUR] Le raccourci n'a pas pu etre cree.
echo Creez-le manuellement : clic droit sur e-school.html
echo puis "Envoyer vers" ^> "Bureau".
echo.
pause
exit /b 1
