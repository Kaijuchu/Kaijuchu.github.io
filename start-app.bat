@echo off
rem ---- A+ Study Hub launcher: serves the app on localhost so AI calls work ----
rem ---- Uses built-in Windows PowerShell - nothing to install ----
cd /d "%~dp0"
title A+ Study Hub server
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0serve.ps1"
if errorlevel 1 pause
