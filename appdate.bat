@echo off
[cite_start]:: בדיקה אם הסקריפט רץ כמנהל [cite: 1]
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -WindowStyle Hidden -Command "Start-Process 'cmd.exe' -ArgumentList '/c', '%~f0' -Verb RunAs"
    exit
)

:: הרצה כמנהל
echo Running as administrator...

[cite_start]:: התקנת Winget ו-Scoop אם חסר [cite: 2, 3]
echo Checking Winget and Scoop...
where winget >nul 2>&1 || (powershell -NoProfile -ExecutionPolicy Bypass -Command "& { Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $env:TEMP\AppInstaller.appxbundle; Add-AppxPackage -Path $env:TEMP\AppInstaller.appxbundle }")
where scoop >nul 2>&1 || (powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (iwr 'https://get.scoop.sh' -UseBasicParsing).Content")

[cite_start]:: הוספת מקורות ל-Scoop ו-Winget [cite: 3]
echo Updating sources...
powershell -NoProfile -ExecutionPolicy Bypass -Command "foreach ($bucket in @('extras','versions','nerd-fonts','games','nonportable')) { if (-not (scoop bucket list | Select-String $bucket)) { scoop bucket add $bucket } }"

[cite_start]:: עדכון אפליקציות מערכת (Winget & Scoop) [cite: 3]
echo Updating system packages...
winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --silent
scoop update && scoop update *

:: --- עדכוני פיתוח (חדש) ---

:: עדכון NPM (גלובלי)
where npm >nul 2>&1
if %errorlevel% equ 0 (
    echo Updating Global NPM packages...
    call npm install -g npm@latest
    call npm update -g
)

:: עדכון Python Packages (pip)
where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Updating Python pip packages...
    python -m pip install --upgrade pip
    :: פקודה שמעדכנת את כל החבילות שמותקנות גלובלית
    powershell -NoProfile -ExecutionPolicy Bypass -Command "pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object { pip install --upgrade $_.name }"
)

echo Done! Everything is up to date.
[cite_start]:: פתיחת cmd אינטראקטיבי [cite: 3]
cmd /k