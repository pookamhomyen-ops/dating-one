@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

:: ============================================================
::   Installer: Dart to Markdown - Right-click Context Menu
::   No hardcoded path - reads its own current folder every run
:: ============================================================

:: ---------- 1) Check for Admin rights, elevate if needed ----------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Administrator privileges required. Requesting UAC elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: ---------- 2) Detect current script folder automatically ----------
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "TARGET_BAT=%SCRIPT_DIR%\dart_to_md.bat"
set "MENU_LABEL=⚡ Dart to Markdown"
set "REG_ROOT=HKCR\SystemFileAssociations\.dart\shell\DartToMarkdown"

echo ============================================================
echo   Detected folder : %SCRIPT_DIR%
echo   Target script    : %TARGET_BAT%
echo ============================================================
echo.

:: ---------- 3) Warn if dart_to_md.bat is missing ----------
if not exist "%TARGET_BAT%" (
    echo [!] WARNING: "dart_to_md.bat" was not found in this folder.
    echo     The menu will still be installed, but it will not work
    echo     until that file exists here.
    echo.
)

:: ---------- 4) Write Registry keys ----------
reg add "%REG_ROOT%" /ve /d "%MENU_LABEL%" /f >nul
reg add "%REG_ROOT%" /v "Icon" /d "shell32.dll,-42" /f >nul
reg add "%REG_ROOT%\command" /ve /d "\"%TARGET_BAT%\" \"%%1\"" /f >nul

if %errorlevel% equ 0 (
    echo [OK] Context menu installed successfully!
    echo      Right-click any .dart file to see "%MENU_LABEL%"
) else (
    echo [X] Something went wrong while writing to the Registry.
)

:: ---------- 5) Restart Explorer so the menu shows up immediately ----------
echo.
echo Restarting Explorer to refresh the context menu...
taskkill /f /im explorer.exe >nul 2>&1
start "" explorer.exe

echo.
echo ============================================================
echo   If you move this folder later, just run install.bat again.
echo   It will automatically update the Registry to the new path.
echo ============================================================
echo.
pause
endlocal
