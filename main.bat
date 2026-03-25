@echo off
setlocal enabledelayedexpansion

:: --- בדיקת הרשאות מנהל (Administrator) ---
openfiles >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Requesting Administrator privileges...
    powershell -Command "Start-Process -FilePath '%0' -Verb RunAs"
    exit /b
)

title Windows Dev Stack Updater
echo ===================================================
echo        System and Dev Environment Auto-Updater
echo ===================================================
echo.

:: --- עדכון Winget ---
echo [+] Checking Winget updates...
where winget >nul 2>&1
if %errorlevel% equ 0 (
    echo Updating packages via Winget...
    winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements
) else (
    echo [!] Winget not found. Skipping...
)

:: --- עדכון Scoop ---
echo.
echo [+] Checking Scoop updates...
where scoop >nul 2>&1
if %errorlevel% equ 0 (
    :: Scoop לא תמיד אוהב לרוץ כאדמין ישיר, לכן נריץ דרך PowerShell
    powershell -NoProfile -ExecutionPolicy Bypass -Command "scoop update; scoop update *"
) else (
    echo [!] Scoop not found. Skipping...
)

:: --- עדכוני פיתוח (NPM) ---
echo.
echo [+] Checking NPM global packages...
where npm >nul 2>&1
if %errorlevel% equ 0 (
    echo Updating Global NPM...
    call npm install -g npm@latest
    call npm update -g
) else (
    echo [!] NPM not found. Skipping...
)

:: --- עדכוני פיתוח (Python/PIP) ---
echo.
echo [+] Checking Python PIP packages...
where pip >nul 2>&1
if %errorlevel% equ 0 (
    echo Upgrading PIP...
    python -m pip install --upgrade pip
    echo Upgrading all outdated global packages...
    :: פקודה יעילה יותר לעדכון כל חבילות ה-PIP
    powershell -NoProfile -ExecutionPolicy Bypass -Command "pip list --outdated --format=json | ConvertFrom-Json | ForEach-Object { pip install --upgrade $_.name }"
) else (
    echo [!] PIP not found. Skipping...
)

echo.
echo ===================================================
echo   Update Complete! All systems are up to date.
echo ===================================================
pause