@echo off
:: בדיקה אם הסקריפט רץ כמנהל
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -WindowStyle Hidden -Command "Start-Process 'cmd.exe' -ArgumentList '/c', '%~f0' -Verb RunAs"
    exit
)

:: אם הגעת לכאן - אתה כבר רץ כמנהל
echo Running as administrator.


:: מתקין מעדכנים
echo Installs Winget Scoop if not installed...
where winget >nul 2>&1 || (powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $env:TEMP\AppInstaller.appxbundle; Add-AppxPackage -Path $env:TEMP\AppInstaller.appxbundle }") & powershell -NoProfile -ExecutionPolicy Bypass -Command "if (-not (Test-Path \"$env:USERPROFILE\scoop\")) { iex (iwr 'https://get.scoop.sh' -UseBasicParsing).Content }"


:: מוסיף מקורות
echo Adds sources...
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($bucket in @('extras','versions','nerd-fonts','games','nonportable')) { if (-not (scoop bucket list | Select-String $bucket)) { scoop bucket add $bucket } }" & (winget source list | findstr /I winget >nul || (winget source add --name winget --arg https://winget.azureedge.net/cache))


:: מעדכן
winget upgrade --id Microsoft.DesktopAppInstaller --accept-package-agreements --accept-source-agreements --silent
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
scoop update && scoop update *



:: ואז פותח cmd אינטראקטיבי
cmd /k
