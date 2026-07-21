@echo off
setlocal enabledelayedexpansion
title A+ Study Hub - GitHub sync
cd /d "%~dp0"

rem ---------- locate git (system install, or the copy bundled with GitHub Desktop) ----------
set "GIT="
where git >nul 2>nul && set "GIT=git"
if not defined GIT (
    for /d %%D in ("%LOCALAPPDATA%\GitHubDesktop\app-*") do (
        if exist "%%D\resources\app\git\cmd\git.exe" set "GIT=%%D\resources\app\git\cmd\git.exe"
    )
)
if not defined GIT (
    echo Couldn't find Git on this PC.
    echo Install Git for Windows from https://git-scm.com/download/win then run this again.
    pause & exit /b 1
)

echo.
echo   A+ Study Hub - GitHub sync
echo   ---------------------------
echo    [1] First-time setup   (connect this folder to your GitHub repo)
echo    [2] Sync now           (push all changes to GitHub)
echo    [3] Enable auto-sync   (pushes automatically every 15 min + at login)
echo    [4] Disable auto-sync
echo.
set /p c=Pick 1, 2, 3 or 4:

if "%c%"=="1" goto setup
if "%c%"=="2" goto sync
if "%c%"=="3" goto enable
if "%c%"=="4" goto disable
echo Nothing chosen. & pause & exit /b

:setup
echo.
set /p url=Paste your repo URL (e.g. https://github.com/Kaijuchu/CompTIA-A-Study-Hub.git):
if "%url%"=="" (echo No URL given. & pause & exit /b 1)
if not exist ".git" (
    "%GIT%" init -b main >nul
)
"%GIT%" remote remove origin >nul 2>nul
"%GIT%" remote add origin "%url%"
> .gitignore echo # local-only files
>> .gitignore echo aplus-progress-*.json
>> .gitignore echo *.mp4
echo Fetching the existing repo...
"%GIT%" fetch origin main
if errorlevel 1 (
    echo.
    echo Couldn't reach the repo. Check the URL, then try again.
    pause & exit /b 1
)
"%GIT%" update-ref refs/heads/main origin/main
"%GIT%" symbolic-ref HEAD refs/heads/main
"%GIT%" reset --mixed >nul
"%GIT%" add -A
"%GIT%" commit -m "Connect local study folder" >nul 2>nul
echo.
echo Pushing... (a GitHub login window may appear the first time)
"%GIT%" push -u origin main
if errorlevel 1 (
    echo.
    echo Push failed - usually a sign-in issue.
    echo Open GitHub Desktop, sign in, then run option 2 here.
    pause & exit /b 1
)
echo.
echo Setup complete! Use option 2 to sync anytime, or option 3 for automatic syncing.
pause & exit /b

:sync
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync.ps1"
exit /b

:enable
if not exist ".git" (echo Run option 1 first. & pause & exit /b 1)
powershell -NoProfile -Command "$s=(New-Object -ComObject WScript.Shell).CreateShortcut([Environment]::GetFolderPath('Startup')+'\APlusStudyHubSync.lnk');$s.TargetPath='%~dp0start-sync-hidden.vbs';$s.WorkingDirectory='%~dp0';$s.Save()"
call :stoploop
wscript "%~dp0start-sync-hidden.vbs"
echo.
echo Auto-sync enabled - running now, and it starts automatically at every login.
echo Changes are committed and pushed every 15 minutes.
pause & exit /b

:disable
del "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup\APlusStudyHubSync.lnk" 2>nul
call :stoploop
echo Auto-sync disabled. Use option 2 to sync manually.
pause & exit /b

:stoploop
powershell -NoProfile -Command "Get-CimInstance Win32_Process -Filter \"Name='powershell.exe'\" | Where-Object { $_.CommandLine -like '*sync-loop.ps1*' } | ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }" >nul 2>nul
exit /b
