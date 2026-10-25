@echo off
setlocal enabledelayedexpansion
title GestSchool - Installation du raccourci sur le Bureau
cd /d "%~dp0"

echo.
echo ==========================================================
echo    GestSchool - Raccourci sur le Bureau
echo ==========================================================
echo.
echo Ce script installe une icone GestSchool sur votre Bureau.
echo Aucune installation, aucun outil a telecharger.
echo.

if not exist "%~dp0GestSchool.html" (
    echo [ERREUR] Le fichier GestSchool.html est introuvable.
    echo Gardez ce script dans le meme dossier que GestSchool.html.
    echo.
    pause
    exit /b 1
)

rem ---------- Adresse du logiciel ----------
set "APPURL=%~dp0GestSchool.html"
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
set "VBSFILE=%TEMP%\gestschool_shortcut.vbs"

echo Set oWS = WScript.CreateObject("WScript.Shell")> "%VBSFILE%"
echo sDesk = oWS.SpecialFolders("Desktop")>> "%VBSFILE%"
echo Set oLink = oWS.CreateShortcut(sDesk ^& "\GestSchool.lnk")>> "%VBSFILE%"
echo oLink.TargetPath = "!BROWSER!">> "%VBSFILE%"
echo oLink.Arguments = "--app=""file:///%APPURL%"" --window-size=1400,900">> "%VBSFILE%"
echo oLink.WorkingDirectory = "%~dp0">> "%VBSFILE%"
echo oLink.IconLocation = "%~dp0icon.ico">> "%VBSFILE%"
echo oLink.Description = "GestSchool">> "%VBSFILE%"
echo oLink.Save>> "%VBSFILE%"
echo WScript.Quit 0>> "%VBSFILE%"

cscript //nologo "%VBSFILE%"
if errorlevel 1 goto VBSFAIL
del "%VBSFILE%" >nul 2>&1

echo ==========================================================
echo    TERMINE
echo ==========================================================
echo.
echo Une icone "GestSchool" est maintenant sur votre Bureau.
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
echo Set oLink = oWS.CreateShortcut(sDesk ^& "\GestSchool.lnk")>> "%VBSFILE%"
echo oLink.TargetPath = "%~dp0GestSchool.html">> "%VBSFILE%"
echo oLink.WorkingDirectory = "%~dp0">> "%VBSFILE%"
echo oLink.IconLocation = "%~dp0icon.ico">> "%VBSFILE%"
echo oLink.Description = "GestSchool">> "%VBSFILE%"
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
echo Creez-le manuellement : clic droit sur GestSchool.html
echo puis "Envoyer vers" ^> "Bureau".
echo.
pause
exit /b 1
