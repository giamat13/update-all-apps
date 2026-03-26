@echo off
setlocal enabledelayedexpansion

:: =====================================================
:: Windows Dev Stack Auto-Updater - Enhanced Edition
:: =====================================================

:: --- בדיקת הרשאות מנהל (Administrator) ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Not running as Administrator. Restarting with elevated privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
        "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"%~f0\" %*' -Verb RunAs"
    exit /b
)

:: --- פרסור ארגומנטים ---
set "DRY_RUN=0"
set "SKIP_WINGET=0"
set "SKIP_SCOOP=0"
set "SKIP_CHOCO=0"
set "SKIP_NPM=0"
set "SKIP_PIP=0"
set "SKIP_CARGO=0"

for %%A in (%*) do (
    if /i "%%A"=="--dry-run"       set "DRY_RUN=1"
    if /i "%%A"=="--skip-winget"   set "SKIP_WINGET=1"
    if /i "%%A"=="--skip-scoop"    set "SKIP_SCOOP=1"
    if /i "%%A"=="--skip-choco"    set "SKIP_CHOCO=1"
    if /i "%%A"=="--skip-npm"      set "SKIP_NPM=1"
    if /i "%%A"=="--skip-pip"      set "SKIP_PIP=1"
    if /i "%%A"=="--skip-cargo"    set "SKIP_CARGO=1"
)

:: --- הגדרת תיקיית לוגים בטוחה (בתוך TEMP) ---
set "LOG_DIR=%TEMP%\WinAutoUpdater\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
set "LOG_FILE=%LOG_DIR%\update_%DATE:~-4%-%DATE:~3,2%-%DATE:~0,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%.log"
set "LOG_FILE=%LOG_FILE: =0%"

:: פונקציית לוג
call :log_init

title Windows Dev Stack Updater
echo ===================================================
echo        System and Dev Environment Auto-Updater
echo ===================================================
if "%DRY_RUN%"=="1" (
    echo   [DRY RUN MODE - No changes will be made]
)
echo   Log file: %LOG_FILE%
echo ===================================================
echo.

:: --- בדיקת חיבור לאינטרנט ---
echo [*] Checking internet connection...
call :log_msg "INFO" "Checking internet connection..."
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    ping -n 1 1.1.1.1 >nul 2>&1
    if !errorlevel! neq 0 (
        echo [!!!] ERROR: No internet connection detected. Aborting.
        call :log_msg "ERROR" "No internet connection. Aborting."
        cmd /k
        exit /b 1
    )
)
echo [OK] Internet connection verified.
call :log_msg "INFO" "Internet connection OK."
echo.

:: --- מעקב כמות עדכונים ---
set "TOTAL_UPDATED=0"
set "TOTAL_ERRORS=0"
set "SUMMARY="

:: =================================================
:: 1. WINGET
:: =================================================
if "%SKIP_WINGET%"=="0" (
    echo [+] Checking Winget updates...
    call :log_msg "INFO" "--- WINGET ---"
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo [DRY RUN] Would run: winget upgrade --all
            call :log_msg "DRY" "winget upgrade --all --include-unknown"
        ) else (
            echo Updating packages via Winget...
            winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements >> "%LOG_FILE%" 2>&1
            if !errorlevel! equ 0 (
                echo [OK] Winget update completed.
                call :log_msg "OK" "Winget update completed successfully."
                set /a TOTAL_UPDATED+=1
                set "SUMMARY=!SUMMARY!  [OK] Winget^|"
            ) else (
                echo [WARN] Winget finished with warnings ^(some packages may have failed^).
                call :log_msg "WARN" "Winget finished with non-zero exit code."
                set /a TOTAL_ERRORS+=1
                set "SUMMARY=!SUMMARY!  [WARN] Winget^|"
            )
        )
    ) else (
        echo [!] Winget not found. Skipping...
        call :log_msg "SKIP" "Winget not found."
        set "SUMMARY=!SUMMARY!  [SKIP] Winget^|"
    )
) else (
    echo [~] Skipping Winget ^(--skip-winget^).
    call :log_msg "SKIP" "Winget skipped by user flag."
)
echo.

:: =================================================
:: 2. SCOOP
:: =================================================
if "%SKIP_SCOOP%"=="0" (
    echo [+] Checking Scoop updates...
    call :log_msg "INFO" "--- SCOOP ---"
    where scoop >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo [DRY RUN] Would run: scoop update + scoop update *
            call :log_msg "DRY" "scoop update; scoop update *"
        ) else (
            powershell -NoProfile -ExecutionPolicy Bypass -Command "scoop update; scoop update *" >> "%LOG_FILE%" 2>&1
            if !errorlevel! equ 0 (
                echo [OK] Scoop update completed.
                call :log_msg "OK" "Scoop update completed."
                set /a TOTAL_UPDATED+=1
                set "SUMMARY=!SUMMARY!  [OK] Scoop^|"
            ) else (
                echo [WARN] Scoop finished with warnings.
                call :log_msg "WARN" "Scoop finished with non-zero exit code."
                set /a TOTAL_ERRORS+=1
                set "SUMMARY=!SUMMARY!  [WARN] Scoop^|"
            )
        )
    ) else (
        echo [!] Scoop not found. Skipping...
        call :log_msg "SKIP" "Scoop not found."
        set "SUMMARY=!SUMMARY!  [SKIP] Scoop^|"
    )
) else (
    echo [~] Skipping Scoop ^(--skip-scoop^).
    call :log_msg "SKIP" "Scoop skipped by user flag."
)
echo.

:: =================================================
:: 3. CHOCOLATEY
:: =================================================
if "%SKIP_CHOCO%"=="0" (
    echo [+] Checking Chocolatey updates...
    call :log_msg "INFO" "--- CHOCOLATEY ---"
    where choco >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo [DRY RUN] Would run: choco upgrade all -y
            call :log_msg "DRY" "choco upgrade all -y"
        ) else (
            echo Updating packages via Chocolatey...
            choco upgrade all -y >> "%LOG_FILE%" 2>&1
            if !errorlevel! equ 0 (
                echo [OK] Chocolatey update completed.
                call :log_msg "OK" "Chocolatey update completed."
                set /a TOTAL_UPDATED+=1
                set "SUMMARY=!SUMMARY!  [OK] Chocolatey^|"
            ) else (
                echo [WARN] Chocolatey finished with warnings.
                call :log_msg "WARN" "Chocolatey finished with non-zero exit code."
                set /a TOTAL_ERRORS+=1
                set "SUMMARY=!SUMMARY!  [WARN] Chocolatey^|"
            )
        )
    ) else (
        echo [!] Chocolatey not found. Skipping...
        call :log_msg "SKIP" "Chocolatey not found."
        set "SUMMARY=!SUMMARY!  [SKIP] Chocolatey^|"
    )
) else (
    echo [~] Skipping Chocolatey ^(--skip-choco^).
    call :log_msg "SKIP" "Chocolatey skipped by user flag."
)
echo.

:: =================================================
:: 4. NPM
:: =================================================
if "%SKIP_NPM%"=="0" (
    echo [+] Checking NPM global packages...
    call :log_msg "INFO" "--- NPM ---"
    where npm >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo [DRY RUN] Would run: npm install -g npm@latest + npm update -g
            call :log_msg "DRY" "npm install -g npm@latest; npm update -g"
        ) else (
            echo Updating NPM itself...
            call npm install -g npm@latest >> "%LOG_FILE%" 2>&1
            echo Updating global NPM packages...
            call npm update -g >> "%LOG_FILE%" 2>&1
            if !errorlevel! equ 0 (
                echo [OK] NPM update completed.
                call :log_msg "OK" "NPM update completed."
                set /a TOTAL_UPDATED+=1
                set "SUMMARY=!SUMMARY!  [OK] NPM^|"
            ) else (
                echo [WARN] NPM finished with warnings.
                call :log_msg "WARN" "NPM finished with non-zero exit code."
                set /a TOTAL_ERRORS+=1
                set "SUMMARY=!SUMMARY!  [WARN] NPM^|"
            )
        )
    ) else (
        echo [!] NPM not found. Skipping...
        call :log_msg "SKIP" "NPM not found."
        set "SUMMARY=!SUMMARY!  [SKIP] NPM^|"
    )
) else (
    echo [~] Skipping NPM ^(--skip-npm^).
    call :log_msg "SKIP" "NPM skipped by user flag."
)
echo.

:: =================================================
:: 5. PIP / PYTHON -M PIP (fallback)
:: =================================================
if "%SKIP_PIP%"=="0" (
    echo [+] Checking Python PIP packages...
    call :log_msg "INFO" "--- PIP ---"

    set "PIP_CMD="
    set "PYTHON_CMD="

    :: נסה pip ישיר
    where pip >nul 2>&1
    if !errorlevel! equ 0 (
        set "PIP_CMD=pip"
    )

    :: נסה pip3 כגיבוי
    if "!PIP_CMD!"=="" (
        where pip3 >nul 2>&1
        if !errorlevel! equ 0 (
            set "PIP_CMD=pip3"
        )
    )

    :: נסה python -m pip כגיבוי
    if "!PIP_CMD!"=="" (
        where python >nul 2>&1
        if !errorlevel! equ 0 (
            python -m pip --version >nul 2>&1
            if !errorlevel! equ 0 (
                set "PIP_CMD=python -m pip"
                set "PYTHON_CMD=python"
            )
        )
    )

    :: נסה python3 -m pip כגיבוי אחרון
    if "!PIP_CMD!"=="" (
        where python3 >nul 2>&1
        if !errorlevel! equ 0 (
            python3 -m pip --version >nul 2>&1
            if !errorlevel! equ 0 (
                set "PIP_CMD=python3 -m pip"
                set "PYTHON_CMD=python3"
            )
        )
    )

    if "!PIP_CMD!"=="" (
        echo [!] PIP not found ^(tried pip, pip3, python -m pip, python3 -m pip^). Skipping...
        call :log_msg "SKIP" "PIP not found via any method."
        set "SUMMARY=!SUMMARY!  [SKIP] PIP^|"
    ) else (
        echo [*] Using: !PIP_CMD!
        call :log_msg "INFO" "Using PIP command: !PIP_CMD!"

        if "%DRY_RUN%"=="1" (
            echo [DRY RUN] Would run: !PIP_CMD! install --upgrade pip + upgrade outdated packages
            call :log_msg "DRY" "!PIP_CMD! install --upgrade pip; upgrade all outdated"
        ) else (
            echo Upgrading PIP...
            !PIP_CMD! install --upgrade pip >> "%LOG_FILE%" 2>&1

            echo Upgrading all outdated global packages ^(safe mode^)...
            :: שיטה בטוחה יותר - עדכון אחד-אחד עם המשך גם אם אחד נכשל
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                "& { $cmd = '!PIP_CMD!'; $pkg = & $cmd.Split(' ') list --outdated --format=json 2>$null | ConvertFrom-Json; if ($pkg) { foreach ($p in $pkg) { Write-Host \"Upgrading $($p.name)...\"; & $cmd.Split(' ') install --upgrade $p.name 2>&1 } } else { Write-Host 'All packages up to date.' } }" >> "%LOG_FILE%" 2>&1

            echo [OK] PIP update completed.
            call :log_msg "OK" "PIP update completed."
            set /a TOTAL_UPDATED+=1
            set "SUMMARY=!SUMMARY!  [OK] PIP (!PIP_CMD!)^|"
        )
    )
) else (
    echo [~] Skipping PIP ^(--skip-pip^).
    call :log_msg "SKIP" "PIP skipped by user flag."
)
echo.

:: =================================================
:: 6. CARGO (Rust)
:: =================================================
if "%SKIP_CARGO%"=="0" (
    echo [+] Checking Cargo ^(Rust^) packages...
    call :log_msg "INFO" "--- CARGO ---"
    where cargo >nul 2>&1
    if !errorlevel! equ 0 (
        where cargo-install-update >nul 2>&1
        if !errorlevel! equ 0 (
            if "%DRY_RUN%"=="1" (
                echo [DRY RUN] Would run: cargo install-update -a
                call :log_msg "DRY" "cargo install-update -a"
            ) else (
                echo Updating all installed Cargo packages...
                cargo install-update -a >> "%LOG_FILE%" 2>&1
                if !errorlevel! equ 0 (
                    echo [OK] Cargo packages updated.
                    call :log_msg "OK" "Cargo update completed."
                    set /a TOTAL_UPDATED+=1
                    set "SUMMARY=!SUMMARY!  [OK] Cargo^|"
                ) else (
                    echo [WARN] Cargo update finished with warnings.
                    call :log_msg "WARN" "Cargo update non-zero exit."
                    set /a TOTAL_ERRORS+=1
                    set "SUMMARY=!SUMMARY!  [WARN] Cargo^|"
                )
            )
        ) else (
            echo [*] cargo-install-update not found. Installing it first...
            call :log_msg "INFO" "Installing cargo-update tool..."
            if "%DRY_RUN%"=="0" (
                cargo install cargo-update >> "%LOG_FILE%" 2>&1
                cargo install-update -a >> "%LOG_FILE%" 2>&1
                echo [OK] Cargo bootstrapped and updated.
                call :log_msg "OK" "Cargo bootstrapped and updated."
                set /a TOTAL_UPDATED+=1
                set "SUMMARY=!SUMMARY!  [OK] Cargo^|"
            ) else (
                echo [DRY RUN] Would install cargo-update then run cargo install-update -a
                call :log_msg "DRY" "cargo install cargo-update; cargo install-update -a"
            )
        )
    ) else (
        echo [!] Cargo not found. Skipping...
        call :log_msg "SKIP" "Cargo not found."
        set "SUMMARY=!SUMMARY!  [SKIP] Cargo^|"
    )
) else (
    echo [~] Skipping Cargo ^(--skip-cargo^).
    call :log_msg "SKIP" "Cargo skipped by user flag."
)
echo.

:: =================================================
:: סיכום
:: =================================================
echo ===================================================
echo   Update %DATE% %TIME%
echo ===================================================
echo   Managers updated/checked: %TOTAL_UPDATED%
echo   Warnings/Errors:          %TOTAL_ERRORS%
echo.
echo   Per-manager summary:
for %%S in (!SUMMARY!) do (
    echo   %%S
)
echo.
echo   Full log: %LOG_FILE%
echo ===================================================
call :log_msg "SUMMARY" "Done. Updated=%TOTAL_UPDATED% Errors=%TOTAL_ERRORS%"

cmd /k
exit /b

:: =================================================
:: פונקציות עזר
:: =================================================
:log_init
    echo Windows Auto-Updater Log > "%LOG_FILE%"
    echo Started: %DATE% %TIME% >> "%LOG_FILE%"
    echo ========================================== >> "%LOG_FILE%"
    exit /b

:log_msg
    :: %1 = רמה (INFO/OK/WARN/ERROR/SKIP/DRY/SUMMARY)
    :: %2 = הודעה
    echo [%TIME%] [%~1] %~2 >> "%LOG_FILE%"
    exit /b