@echo off
echo Arret de GestSchool...
taskkill /f /im python.exe /fi "WINDOWTITLE eq GestSchool*" >nul 2>&1
for /f "tokens=5" %%a in ('netstat -aon ^| find ":8765" ^| find "LISTENING"') do taskkill /f /pid %%a >nul 2>&1
echo Application arretee.
timeout /t 1 >nul
