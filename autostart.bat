@echo off
title A+ Study Hub - autostart manager
echo.
echo  A+ Study Hub - background server manager
echo  -----------------------------------------
echo   [1] Enable auto-start  (server runs silently every time you log in)
echo   [2] Disable auto-start
echo   [3] Stop the background server now
echo.
set /p c=Pick 1, 2 or 3:

if "%c%"=="1" (
    powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Startup')+'\APlusStudyHub.lnk');$s.TargetPath='%~dp0start-hidden.vbs';$s.WorkingDirectory='%~dp0';$s.Save()"
    wscript "%~dp0start-hidden.vbs"
    echo.
    echo Done! The server is running now and will auto-start at every login.
    echo Bookmark this:  http://localhost:8765/index.html
) else if "%c%"=="2" (
    del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\APlusStudyHub.lnk" 2>nul
    echo Auto-start disabled. Use start-app.bat to run it manually.
) else if "%c%"=="3" (
    powershell -NoProfile -Command "Get-NetTCPConnection -LocalPort 8765 -State Listen -ErrorAction SilentlyContinue | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }"
    echo Server stopped.
) else (
    echo Nothing chosen.
)
echo.
pause
