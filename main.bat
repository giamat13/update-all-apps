@echo off
setlocal enabledelayedexpansion

:: =====================================================
:: Windows Dev Stack Auto-Updater - Enhanced Edition v3
:: =====================================================

:: --- Admin check ---
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Not running as Administrator. Restarting elevated...
    powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c \"%~f0\" %*' -Verb RunAs"
    exit /b
)

:: --- Argument parsing ---
set "DRY_RUN=0"
set "SKIP_WINGET=0"
set "SKIP_SCOOP=0"
set "SKIP_CHOCO=0"
set "SKIP_NPM=0"
set "SKIP_PNPM=0"
set "SKIP_YARN=0"
set "SKIP_PIP=0"
set "SKIP_UV=0"
set "SKIP_CONDA=0"
set "SKIP_CARGO=0"
set "SKIP_GEM=0"
set "SKIP_COMPOSER=0"
set "SKIP_DOTNET=0"
set "SKIP_WINUPDATE=0"
set "SKIP_PSMODULES=0"
set "SKIP_RUSTUP=0"
set "SKIP_WSL=0"
set "SKIP_VSCODE=0"
set "SKIP_OMP=0"

for %%A in (%*) do (
    if /i "%%A"=="--dry-run"        set "DRY_RUN=1"
    if /i "%%A"=="--skip-winget"    set "SKIP_WINGET=1"
    if /i "%%A"=="--skip-scoop"     set "SKIP_SCOOP=1"
    if /i "%%A"=="--skip-choco"     set "SKIP_CHOCO=1"
    if /i "%%A"=="--skip-npm"       set "SKIP_NPM=1"
    if /i "%%A"=="--skip-pnpm"      set "SKIP_PNPM=1"
    if /i "%%A"=="--skip-yarn"      set "SKIP_YARN=1"
    if /i "%%A"=="--skip-pip"       set "SKIP_PIP=1"
    if /i "%%A"=="--skip-uv"        set "SKIP_UV=1"
    if /i "%%A"=="--skip-conda"     set "SKIP_CONDA=1"
    if /i "%%A"=="--skip-cargo"     set "SKIP_CARGO=1"
    if /i "%%A"=="--skip-gem"       set "SKIP_GEM=1"
    if /i "%%A"=="--skip-composer"  set "SKIP_COMPOSER=1"
    if /i "%%A"=="--skip-dotnet"    set "SKIP_DOTNET=1"
    if /i "%%A"=="--skip-winupdate" set "SKIP_WINUPDATE=1"
    if /i "%%A"=="--skip-psmodules" set "SKIP_PSMODULES=1"
    if /i "%%A"=="--skip-rustup"    set "SKIP_RUSTUP=1"
    if /i "%%A"=="--skip-wsl"       set "SKIP_WSL=1"
    if /i "%%A"=="--skip-vscode"    set "SKIP_VSCODE=1"
    if /i "%%A"=="--skip-omp"       set "SKIP_OMP=1"
)

:: --- Timeouts (seconds) ---
set "TO_WINGET=14400"
set "TO_SCOOP=7200"
set "TO_CHOCO=10800"
set "TO_NPM=1800"
set "TO_PNPM=1800"
set "TO_YARN=1800"
set "TO_PIP=3600"
set "TO_UV=3600"
set "TO_CONDA=7200"
set "TO_CARGO=7200"
set "TO_GEM=3600"
set "TO_COMPOSER=1800"
set "TO_DOTNET=3600"
set "TO_WINUPDATE=7200"
set "TO_PSMODULES=1800"
set "TO_RUSTUP=3600"
set "TO_WSL=600"
set "TO_VSCODE=900"
set "TO_OMP=300"

:: --- Log setup (locale-safe date via PowerShell) ---
set "LOG_DIR=%TEMP%\WinAutoUpdater\logs"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"
for /f "delims=" %%T in ('powershell -NoProfile -Command "Get-Date -Format 'yyyy-MM-dd_HHmmss'"') do set "TIMESTAMP=%%T"
set "LOG_FILE=%LOG_DIR%\update_%TIMESTAMP%.log"

call :log_init

:: --- Capture script start time for elapsed display ---
for /f %%F in ('powershell -NoProfile -Command "(Get-Date).ToFileTime()"') do set "SCRIPT_START_FTIME=%%F"

:: --- Header ---
title Windows Dev Stack Updater v3
echo.
echo   ===========================================================
echo         Windows Dev Stack Auto-Updater  v3.0
echo   ===========================================================
if "%DRY_RUN%"=="1" echo   [DRY RUN - no changes will be made]
echo   Log: %LOG_FILE%
echo   ===========================================================
echo.

:: --- Count active steps for progress bar ---
set "TOTAL_STEPS=0"
set "CURRENT_STEP=0"
if "%SKIP_WINGET%"=="0"    set /a TOTAL_STEPS+=1
if "%SKIP_SCOOP%"=="0"     set /a TOTAL_STEPS+=1
if "%SKIP_CHOCO%"=="0"     set /a TOTAL_STEPS+=1
if "%SKIP_NPM%"=="0"       set /a TOTAL_STEPS+=1
if "%SKIP_PNPM%"=="0"      set /a TOTAL_STEPS+=1
if "%SKIP_YARN%"=="0"      set /a TOTAL_STEPS+=1
if "%SKIP_PIP%"=="0"       set /a TOTAL_STEPS+=1
if "%SKIP_UV%"=="0"        set /a TOTAL_STEPS+=1
if "%SKIP_CONDA%"=="0"     set /a TOTAL_STEPS+=1
if "%SKIP_CARGO%"=="0"     set /a TOTAL_STEPS+=1
if "%SKIP_GEM%"=="0"       set /a TOTAL_STEPS+=1
if "%SKIP_COMPOSER%"=="0"  set /a TOTAL_STEPS+=1
if "%SKIP_DOTNET%"=="0"    set /a TOTAL_STEPS+=1
if "%SKIP_WINUPDATE%"=="0" set /a TOTAL_STEPS+=1
if "%SKIP_PSMODULES%"=="0" set /a TOTAL_STEPS+=1
if "%SKIP_RUSTUP%"=="0"    set /a TOTAL_STEPS+=1
if "%SKIP_WSL%"=="0"       set /a TOTAL_STEPS+=1
if "%SKIP_VSCODE%"=="0"    set /a TOTAL_STEPS+=1
if "%SKIP_OMP%"=="0"       set /a TOTAL_STEPS+=1
call :log_msg "INFO" "Total steps: %TOTAL_STEPS%"

:: --- Internet check ---
echo [*] Checking internet connection...
call :log_msg "INFO" "Checking internet..."
ping -n 1 8.8.8.8 >nul 2>&1
if %errorlevel% neq 0 (
    ping -n 1 1.1.1.1 >nul 2>&1
    if !errorlevel! neq 0 (
        echo [!!!] No internet connection. Aborting.
        call :log_msg "ERROR" "No internet. Aborting."
        cmd /k
        exit /b 1
    )
)
echo [OK] Internet OK.
call :log_msg "INFO" "Internet OK."
echo.

:: --- Disk space check (locale-safe, pure PowerShell) ---
echo [*] Checking disk space on C:\...
call :log_msg "INFO" "Checking disk space..."
set "DISK_RESULT=OK:unknown"
powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $d=Get-PSDrive C; $gb=[math]::Round($d.Free/1GB,1); if($gb -lt 5){Write-Host('LOW:'+$gb)}else{Write-Host('OK:'+$gb)} } catch { Write-Host 'OK:unknown' }" > "%TEMP%\diskcheck.tmp" 2>nul
if exist "%TEMP%\diskcheck.tmp" (
    set /p DISK_RESULT=<"%TEMP%\diskcheck.tmp"
    del "%TEMP%\diskcheck.tmp" >nul 2>&1
)
if "!DISK_RESULT:~0,3!"=="LOW" (
    echo [WARN] Low disk space: !DISK_RESULT:~4! GB free. Updates may fail!
    call :log_msg "WARN" "Low disk space: !DISK_RESULT:~4! GB free."
    echo        Press any key to continue or Ctrl+C to abort...
    pause >nul
) else (
    echo [OK] Disk space: !DISK_RESULT:~3! GB free.
    call :log_msg "INFO" "Disk space: !DISK_RESULT:~3! GB free."
)
echo.

:: --- Counters ---
set "TOTAL_UPDATED=0"
set "TOTAL_ERRORS=0"
set "TOTAL_SKIPPED=0"
set "TOTAL_NOTFOUND=0"
set "SUMMARY="

call :log_msg "INFO" "Starting package manager checks..."

:: ==================================================
:: 1. WINGET
:: ==================================================
if "%SKIP_WINGET%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Winget"
    call :log_msg "INFO" "--- WINGET ---"
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --disable-interactivity
            call :log_msg "DRY" "winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --disable-interactivity"
        ) else (
            call :run_with_timeout "winget upgrade --all --include-unknown --accept-package-agreements --accept-source-agreements --disable-interactivity" %TO_WINGET% "Winget"
        )
    ) else (
        echo   [--] Winget not installed. Skipping.
        call :log_msg "SKIP" "Winget not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Winget|"
    )
    echo.
) else (
    echo [~] Skipping Winget ^(--skip-winget^).
    call :log_msg "SKIP" "Winget skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 2. SCOOP
:: ==================================================
if "%SKIP_SCOOP%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Scoop"
    call :log_msg "INFO" "--- SCOOP ---"
    where scoop >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: powershell -NoProfile -ExecutionPolicy Bypass -Command scoop update; scoop update *
            call :log_msg "DRY" "powershell -NoProfile -ExecutionPolicy Bypass -Command scoop update; scoop update *"
        ) else (
            call :run_with_timeout "powershell -NoProfile -ExecutionPolicy Bypass -Command scoop update; scoop update *" %TO_SCOOP% "Scoop"
        )
    ) else (
        echo   [--] Scoop not installed. Skipping.
        call :log_msg "SKIP" "Scoop not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Scoop|"
    )
    echo.
) else (
    echo [~] Skipping Scoop ^(--skip-scoop^).
    call :log_msg "SKIP" "Scoop skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 3. CHOCOLATEY
:: ==================================================
if "%SKIP_CHOCO%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Chocolatey"
    call :log_msg "INFO" "--- CHOCOLATEY ---"
    where choco >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: choco upgrade all -y
            call :log_msg "DRY" "choco upgrade all -y"
        ) else (
            call :run_with_timeout "choco upgrade all -y" %TO_CHOCO% "Chocolatey"
        )
    ) else (
        echo   [--] Chocolatey not installed. Skipping.
        call :log_msg "SKIP" "Chocolatey not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Chocolatey|"
    )
    echo.
) else (
    echo [~] Skipping Chocolatey ^(--skip-choco^).
    call :log_msg "SKIP" "Chocolatey skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 4. NPM
:: ==================================================
if "%SKIP_NPM%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "NPM"
    call :log_msg "INFO" "--- NPM ---"
    where npm >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: cmd /c npm install -g npm@latest && npm update -g
            call :log_msg "DRY" "cmd /c npm install -g npm@latest && npm update -g"
        ) else (
            call :run_with_timeout "cmd /c npm install -g npm@latest && npm update -g" %TO_NPM% "NPM"
        )
    ) else (
        echo   [--] NPM not installed. Skipping.
        call :log_msg "SKIP" "NPM not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] NPM|"
    )
    echo.
) else (
    echo [~] Skipping NPM ^(--skip-npm^).
    call :log_msg "SKIP" "NPM skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 5. PNPM
:: ==================================================
if "%SKIP_PNPM%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "pnpm"
    call :log_msg "INFO" "--- PNPM ---"
    where pnpm >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: cmd /c pnpm self-update && pnpm update -g
            call :log_msg "DRY" "cmd /c pnpm self-update && pnpm update -g"
        ) else (
            call :run_with_timeout "cmd /c pnpm self-update && pnpm update -g" %TO_PNPM% "pnpm"
        )
    ) else (
        echo   [--] pnpm not installed. Skipping.
        call :log_msg "SKIP" "pnpm not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] pnpm|"
    )
    echo.
) else (
    echo [~] Skipping pnpm ^(--skip-pnpm^).
    call :log_msg "SKIP" "pnpm skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 6. YARN
:: ==================================================
if "%SKIP_YARN%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Yarn"
    call :log_msg "INFO" "--- YARN ---"
    where yarn >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: yarn global upgrade
            call :log_msg "DRY" "yarn global upgrade"
        ) else (
            call :run_with_timeout "yarn global upgrade" %TO_YARN% "Yarn"
        )
    ) else (
        echo   [--] Yarn not installed. Skipping.
        call :log_msg "SKIP" "Yarn not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Yarn|"
    )
    echo.
) else (
    echo [~] Skipping Yarn ^(--skip-yarn^).
    call :log_msg "SKIP" "Yarn skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 7. PIP
:: ==================================================
if "%SKIP_PIP%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "PIP"
    call :log_msg "INFO" "--- PIP ---"
    set "PIP_CMD="
    where pip  >nul 2>&1 && set "PIP_CMD=pip"
    if "!PIP_CMD!"=="" ( where pip3 >nul 2>&1 && set "PIP_CMD=pip3" )
    if "!PIP_CMD!"=="" (
        where python >nul 2>&1
        if !errorlevel! equ 0 ( python -m pip --version >nul 2>&1 && set "PIP_CMD=python -m pip" )
    )
    if "!PIP_CMD!"=="" (
        where python3 >nul 2>&1
        if !errorlevel! equ 0 ( python3 -m pip --version >nul 2>&1 && set "PIP_CMD=python3 -m pip" )
    )
    if "!PIP_CMD!"=="" (
        echo   [--] PIP not found. Skipping.
        call :log_msg "SKIP" "PIP not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] PIP|"
    ) else (
        echo   [*] Using: !PIP_CMD!
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would upgrade pip and all outdated packages
            call :log_msg "DRY" "pip upgrade all"
        ) else (
            call :run_with_timeout "cmd /c !PIP_CMD! install --upgrade pip" 300 "PIP-self-upgrade"
            echo   [*] Upgrading outdated packages one by one...
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                "$pip = '!PIP_CMD!'.Split(' ');" ^
                "$pkgs = (& $pip list --outdated --format=json 2>$null | ConvertFrom-Json);" ^
                "if (!$pkgs) { Write-Host 'All PIP packages up to date.'; exit 0 }" ^
                "$total = $pkgs.Count; $i = 0;" ^
                "foreach ($p in $pkgs) {" ^
                "    $i++; Write-Host ('  ['+$i+'/'+$total+'] Upgrading '+$p.name+'...');" ^
                "    & $pip install --upgrade $p.name 2>&1 | Add-Content '%LOG_FILE%'" ^
                "}" >> "%LOG_FILE%" 2>&1
            echo   [OK] PIP update completed.
            call :log_msg "OK" "PIP completed."
            set /a TOTAL_UPDATED+=1
            set "SUMMARY=!SUMMARY![OK] PIP|"
        )
    )
    echo.
) else (
    echo [~] Skipping PIP ^(--skip-pip^).
    call :log_msg "SKIP" "PIP skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 8. UV
:: ==================================================
if "%SKIP_UV%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "uv"
    call :log_msg "INFO" "--- UV ---"
    where uv >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: cmd /c uv self update && uv tool upgrade --all
            call :log_msg "DRY" "cmd /c uv self update && uv tool upgrade --all"
        ) else (
            call :run_with_timeout "cmd /c uv self update && uv tool upgrade --all" %TO_UV% "uv"
        )
    ) else (
        echo   [--] uv not installed. Skipping.
        call :log_msg "SKIP" "uv not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] uv|"
    )
    echo.
) else (
    echo [~] Skipping uv ^(--skip-uv^).
    call :log_msg "SKIP" "uv skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 9. CONDA / MAMBA
:: ==================================================
if "%SKIP_CONDA%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Conda"
    call :log_msg "INFO" "--- CONDA ---"
    set "CONDA_CMD="
    where mamba >nul 2>&1 && set "CONDA_CMD=mamba"
    if "!CONDA_CMD!"=="" ( where conda >nul 2>&1 && set "CONDA_CMD=conda" )
    if "!CONDA_CMD!"=="" (
        echo   [--] Conda/Mamba not installed. Skipping.
        call :log_msg "SKIP" "Conda not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Conda|"
    ) else (
        echo   [*] Using: !CONDA_CMD!
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: !CONDA_CMD! update --all -y
            call :log_msg "DRY" "conda update --all -y"
        ) else (
            call :run_with_timeout "cmd /c !CONDA_CMD! update conda -y && !CONDA_CMD! update --all -y" %TO_CONDA% "Conda"
        )
    )
    echo.
) else (
    echo [~] Skipping Conda ^(--skip-conda^).
    call :log_msg "SKIP" "Conda skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 10. CARGO (Rust)
:: ==================================================
if "%SKIP_CARGO%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Cargo"
    call :log_msg "INFO" "--- CARGO ---"
    where cargo >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: cargo install-update -a
            call :log_msg "DRY" "cargo install-update -a"
        ) else (
            where cargo-install-update >nul 2>&1
            if !errorlevel! neq 0 (
                echo   [*] cargo-update not found. Installing it first...
                call :run_with_timeout "cargo install cargo-update" 1800 "Cargo-bootstrap"
            )
            call :run_with_timeout "cargo install-update -a" %TO_CARGO% "Cargo"
        )
    ) else (
        echo   [--] Cargo not installed. Skipping.
        call :log_msg "SKIP" "Cargo not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Cargo|"
    )
    echo.
) else (
    echo [~] Skipping Cargo ^(--skip-cargo^).
    call :log_msg "SKIP" "Cargo skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 11. RUBYGEMS
:: ==================================================
if "%SKIP_GEM%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "RubyGems"
    call :log_msg "INFO" "--- RUBYGEMS ---"
    where gem >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: cmd /c gem update --system && gem update
            call :log_msg "DRY" "cmd /c gem update --system && gem update"
        ) else (
            call :run_with_timeout "cmd /c gem update --system && gem update" %TO_GEM% "RubyGems"
        )
    ) else (
        echo   [--] RubyGems not installed. Skipping.
        call :log_msg "SKIP" "RubyGems not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] RubyGems|"
    )
    echo.
) else (
    echo [~] Skipping RubyGems ^(--skip-gem^).
    call :log_msg "SKIP" "RubyGems skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 12. COMPOSER
:: ==================================================
if "%SKIP_COMPOSER%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Composer"
    call :log_msg "INFO" "--- COMPOSER ---"
    where composer >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: cmd /c composer self-update && composer global update
            call :log_msg "DRY" "cmd /c composer self-update && composer global update"
        ) else (
            call :run_with_timeout "cmd /c composer self-update && composer global update" %TO_COMPOSER% "Composer"
        )
    ) else (
        echo   [--] Composer not installed. Skipping.
        call :log_msg "SKIP" "Composer not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Composer|"
    )
    echo.
) else (
    echo [~] Skipping Composer ^(--skip-composer^).
    call :log_msg "SKIP" "Composer skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 13. DOTNET TOOLS
:: ==================================================
if "%SKIP_DOTNET%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% ".NET Tools"
    call :log_msg "INFO" "--- DOTNET TOOLS ---"
    where dotnet >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would update all dotnet global tools
            call :log_msg "DRY" "dotnet tool update --global each"
        ) else (
            echo   [*] Updating all dotnet global tools...
            powershell -NoProfile -ExecutionPolicy Bypass -Command ^
                "$tools=(dotnet tool list --global 2>$null)|Select-Object -Skip 2|Where-Object{$_ -match '\S'}|ForEach-Object{($_ -split '\s+')[0]};" ^
                "if(!$tools){Write-Host 'No global dotnet tools.';exit 0}" ^
                "$total=@($tools).Count;$i=0;" ^
                "foreach($t in $tools){$i++;Write-Host('  ['+$i+'/'+$total+'] '+$t);dotnet tool update --global $t 2>&1|Add-Content '%LOG_FILE%'}" >> "%LOG_FILE%" 2>&1
            echo   [OK] .NET Tools updated.
            call :log_msg "OK" ".NET Tools completed."
            set /a TOTAL_UPDATED+=1
            set "SUMMARY=!SUMMARY![OK] .NET Tools|"
        )
    ) else (
        echo   [--] dotnet not installed. Skipping.
        call :log_msg "SKIP" "dotnet not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] .NET Tools|"
    )
    echo.
) else (
    echo [~] Skipping .NET Tools ^(--skip-dotnet^).
    call :log_msg "SKIP" ".NET Tools skipped by flag."
    set /a TOTAL_SKIPPED+=1
)


:: ==================================================
:: 14. WINDOWS UPDATE
:: ==================================================
if "%SKIP_WINUPDATE%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Windows Update"
    call :log_msg "INFO" "--- WINDOWS UPDATE ---"
    if "%DRY_RUN%"=="1" (
        echo   [DRY RUN] Would run: Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot
        call :log_msg "DRY" "Windows Update dry run"
    ) else (
        echo   [*] Ensuring PSWindowsUpdate module is installed...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "if(!(Get-Module -ListAvailable -Name PSWindowsUpdate)){Set-PSRepository PSGallery -InstallationPolicy Trusted -EA SilentlyContinue; Install-Module PSWindowsUpdate -Force -Scope AllUsers -Confirm:$false}" >> "%LOG_FILE%" 2>&1
        echo   [*] Checking for Windows Updates (this may take a while)...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "Import-Module PSWindowsUpdate; $u=Get-WindowsUpdate; if(!$u){Write-Host '  No updates available.'}else{Write-Host ('  '+$u.Count+' update(s) found. Installing...'); Install-WindowsUpdate -AcceptAll -IgnoreReboot -Confirm:$false | Out-Default}"
        if !errorlevel! equ 0 (
            echo   [OK] Windows Update completed.
            call :log_msg "OK" "Windows Update exit=0"
            set /a TOTAL_UPDATED+=1
            set "SUMMARY=!SUMMARY![OK] Windows Update|"
        ) else (
            echo   [WARN] Windows Update exited with errors.
            call :log_msg "WARN" "Windows Update non-zero exit"
            set /a TOTAL_ERRORS+=1
            set "SUMMARY=!SUMMARY![WARN] Windows Update|"
        )
    )
    echo.
) else (
    echo [~] Skipping Windows Update ^(--skip-winupdate^).
    call :log_msg "SKIP" "Windows Update skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 15. POWERSHELL MODULES
:: ==================================================
if "%SKIP_PSMODULES%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "PS Modules"
    call :log_msg "INFO" "--- POWERSHELL MODULES ---"
    if "%DRY_RUN%"=="1" (
        echo   [DRY RUN] Would run: Update-Module -Force for all installed modules
        call :log_msg "DRY" "PS Modules dry run"
    ) else (
        echo   [*] Updating installed PowerShell modules...
        powershell -NoProfile -ExecutionPolicy Bypass -Command "$mods=Get-InstalledModule; if(!$mods){Write-Host '  No modules installed.'}else{$total=$mods.Count;$i=0; foreach($m in $mods){$i++;Write-Host('  ['+$i+'/'+$total+'] '+$m.Name);Update-Module $m.Name -Force -EA SilentlyContinue | Out-Null}}"
        echo   [OK] PS Modules updated.
        call :log_msg "OK" "PS Modules completed."
        set /a TOTAL_UPDATED+=1
        set "SUMMARY=!SUMMARY![OK] PS Modules|"
    )
    echo.
) else (
    echo [~] Skipping PS Modules ^(--skip-psmodules^).
    call :log_msg "SKIP" "PS Modules skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 16. RUSTUP (Rust toolchain)
:: ==================================================
if "%SKIP_RUSTUP%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "Rustup"
    call :log_msg "INFO" "--- RUSTUP ---"
    where rustup >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: rustup update
            call :log_msg "DRY" "rustup update"
        ) else (
            call :run_with_timeout "rustup update" %TO_RUSTUP% "Rustup"
        )
    ) else (
        echo   [--] rustup not installed. Skipping.
        call :log_msg "SKIP" "rustup not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] Rustup|"
    )
    echo.
) else (
    echo [~] Skipping Rustup ^(--skip-rustup^).
    call :log_msg "SKIP" "Rustup skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 17. WSL
:: ==================================================
if "%SKIP_WSL%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "WSL"
    call :log_msg "INFO" "--- WSL ---"
    where wsl >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: wsl --update
            call :log_msg "DRY" "wsl --update"
        ) else (
            call :run_with_timeout "wsl --update" %TO_WSL% "WSL"
        )
    ) else (
        echo   [--] WSL not installed. Skipping.
        call :log_msg "SKIP" "WSL not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] WSL|"
    )
    echo.
) else (
    echo [~] Skipping WSL ^(--skip-wsl^).
    call :log_msg "SKIP" "WSL skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 18. VS CODE EXTENSIONS
:: ==================================================
if "%SKIP_VSCODE%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "VS Code Ext"
    call :log_msg "INFO" "--- VS CODE EXTENSIONS ---"
    where code >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would reinstall all VS Code extensions to update them
            call :log_msg "DRY" "VS Code extensions dry run"
        ) else (
            echo   [*] Updating VS Code extensions...
            powershell -NoProfile -ExecutionPolicy Bypass -Command "$exts=code --list-extensions 2>$null; if(!$exts){Write-Host '  No extensions installed.'}else{$total=@($exts).Count;$i=0; foreach($e in $exts){$i++;Write-Host('  ['+$i+'/'+$total+'] '+$e); code --install-extension $e --force 2>&1 | Out-Null}}"
            echo   [OK] VS Code extensions updated.
            call :log_msg "OK" "VS Code extensions completed."
            set /a TOTAL_UPDATED+=1
            set "SUMMARY=!SUMMARY![OK] VS Code Ext|"
        )
    ) else (
        echo   [--] VS Code not installed. Skipping.
        call :log_msg "SKIP" "VS Code not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] VS Code Ext|"
    )
    echo.
) else (
    echo [~] Skipping VS Code Ext ^(--skip-vscode^).
    call :log_msg "SKIP" "VS Code Ext skipped by flag."
    set /a TOTAL_SKIPPED+=1
)

:: ==================================================
:: 19. OH-MY-POSH
:: ==================================================
if "%SKIP_OMP%"=="0" (
    set /a CURRENT_STEP+=1
    call :draw_progress !CURRENT_STEP! %TOTAL_STEPS% "oh-my-posh"
    call :log_msg "INFO" "--- OH-MY-POSH ---"
    where oh-my-posh >nul 2>&1
    if !errorlevel! equ 0 (
        if "%DRY_RUN%"=="1" (
            echo   [DRY RUN] Would run: oh-my-posh upgrade
            call :log_msg "DRY" "oh-my-posh upgrade"
        ) else (
            call :run_with_timeout "oh-my-posh upgrade" %TO_OMP% "oh-my-posh"
        )
    ) else (
        echo   [--] oh-my-posh not installed. Skipping.
        call :log_msg "SKIP" "oh-my-posh not found."
        set /a TOTAL_NOTFOUND+=1
        set "SUMMARY=!SUMMARY![NOT FOUND] oh-my-posh|"
    )
    echo.
) else (
    echo [~] Skipping oh-my-posh ^(--skip-omp^).
    call :log_msg "SKIP" "oh-my-posh skipped by flag."
    set /a TOTAL_SKIPPED+=1
)
:: ==================================================
:: SUMMARY
:: ==================================================
call :draw_progress %TOTAL_STEPS% %TOTAL_STEPS% "Done!"
echo.
echo   ===========================================================
echo   Update Summary -- %DATE% %TIME%
echo   ===========================================================
echo   Updated/checked:  %TOTAL_UPDATED%
echo   Warnings/errors:  %TOTAL_ERRORS%
echo   Not installed:    %TOTAL_NOTFOUND%
echo   Skipped by flag:  %TOTAL_SKIPPED%
echo.
echo   Per-manager results:
for %%S in (!SUMMARY!) do echo     %%S
echo.
echo   Full log: %LOG_FILE%
echo   ===========================================================
call :log_msg "SUMMARY" "Done. Updated=%TOTAL_UPDATED% Errors=%TOTAL_ERRORS% NotFound=%TOTAL_NOTFOUND% Skipped=%TOTAL_SKIPPED%"

cmd /k
exit /b

:: ==================================================
:: SUBROUTINES
:: ==================================================

:run_with_timeout
:: %1=command  %2=timeout_seconds  %3=display_name
:: Runs process directly to console (no redirect) so output appears live.
:: Timeout is enforced via WaitForExit(ms). Log capture is best-effort via stderr.
    set "RWT_CMD=%~1"
    set "RWT_TIMEOUT=%~2"
    set "RWT_NAME=%~3"
    set "RWT_TMP=%TEMP%\rwt_%RANDOM%.tmp"
    set "RWT_PS1=%TEMP%\rwt_%RANDOM%.ps1"
    echo   [*] Running %RWT_NAME% (timeout: %RWT_TIMEOUT%s)...
    call :log_msg "INFO" "Running %RWT_NAME% cmd: %RWT_CMD%"

    :: Minimal PS1: run directly to console, no redirection, just timeout
    echo $to   = %RWT_TIMEOUT%                                          > "%RWT_PS1%"
    echo $tmp  = '%RWT_TMP%'                                           >> "%RWT_PS1%"
    echo $proc = Start-Process -FilePath 'cmd.exe' -ArgumentList ('/c %RWT_CMD%') -NoNewWindow -PassThru >> "%RWT_PS1%"
    echo $fin  = $proc.WaitForExit($to * 1000)                        >> "%RWT_PS1%"
    echo if (-not $fin) { $proc.Kill(); 'TIMEOUT' ^| Set-Content $tmp } >> "%RWT_PS1%"
    echo else            { ('OK:' + $proc.ExitCode) ^| Set-Content $tmp } >> "%RWT_PS1%"

    powershell -NoProfile -ExecutionPolicy Bypass -File "%RWT_PS1%"
    del "%RWT_PS1%" >nul 2>&1

    set "RWT_RESULT=UNKNOWN"
    if exist "%RWT_TMP%" (
        set /p RWT_RESULT=<"%RWT_TMP%"
        del "%RWT_TMP%" >nul 2>&1
    )

    if "!RWT_RESULT!"=="TIMEOUT" (
        echo   [TIMEOUT] %RWT_NAME% killed after %RWT_TIMEOUT%s.
        call :log_msg "TIMEOUT" "%RWT_NAME% killed after %RWT_TIMEOUT%s."
        set /a TOTAL_ERRORS+=1
        set "SUMMARY=!SUMMARY![TIMEOUT] %RWT_NAME%|"
    ) else if "!RWT_RESULT:~0,3!"=="OK:" (
        set "RWT_EXIT=!RWT_RESULT:~3!"
        if "!RWT_EXIT!"=="0" (
            echo   [OK] %RWT_NAME% completed.
            call :log_msg "OK" "%RWT_NAME% exit=0"
            set /a TOTAL_UPDATED+=1
            set "SUMMARY=!SUMMARY![OK] %RWT_NAME%|"
        ) else (
            echo   [WARN] %RWT_NAME% exit code !RWT_EXIT!.
            call :log_msg "WARN" "%RWT_NAME% exit=!RWT_EXIT!"
            set /a TOTAL_ERRORS+=1
            set "SUMMARY=!SUMMARY![WARN] %RWT_NAME% (exit !RWT_EXIT!)|"
        )
    ) else (
        echo   [WARN] %RWT_NAME% - unknown result.
        call :log_msg "WARN" "%RWT_NAME% unknown result."
        set /a TOTAL_ERRORS+=1
        set "SUMMARY=!SUMMARY![WARN] %RWT_NAME%|"
    )
    exit /b

:draw_progress
:: %1=current  %2=total  %3=label
    if "%~2"=="0" exit /b
    set /a "DP_FILLED=%~1 * 40 / %~2"
    set /a "DP_EMPTY=40 - DP_FILLED"
    set /a "DP_PCT=%~1 * 100 / %~2"
    set "DP_BAR=["
    for /l %%i in (1,1,!DP_FILLED!) do set "DP_BAR=!DP_BAR!#"
    for /l %%i in (1,1,!DP_EMPTY!)  do set "DP_BAR=!DP_BAR!-"
    set "DP_BAR=!DP_BAR!]"
    for /f %%E in ('powershell -NoProfile -Command "$ft=[long]%SCRIPT_START_FTIME%; $e=[int]([datetime]::Now-[datetime]::FromFileTime($ft)).TotalSeconds; $h=[math]::Floor($e/3600); $m=[math]::Floor($e/60)-$h*60; $s=$e-[math]::Floor($e/60)*60; '{0:00}:{1:00}:{2:00}'-f $h,$m,$s"') do set "DP_ELAPSED=%%E"
    echo   !DP_BAR! !DP_PCT!%% -- %~3  [%~1/%~2]  ^(!DP_ELAPSED! elapsed^)
    call :log_msg "STEP" "%~3 (%~1/%~2) elapsed=!DP_ELAPSED!"
    exit /b

:log_init
    echo Windows Auto-Updater v3 Log > "%LOG_FILE%"
    echo Started: %DATE% %TIME% >> "%LOG_FILE%"
    echo ========================================== >> "%LOG_FILE%"
    exit /b

:log_msg
    echo [%TIME%] [%~1] %~2 >> "%LOG_FILE%"
    exit /b