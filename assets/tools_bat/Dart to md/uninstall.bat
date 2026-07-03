@echo off
setlocal
chcp 65001 >nul

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo [!] Administrator privileges required. Requesting UAC elevation...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "REG_ROOT=HKCR\SystemFileAssociations\.dart\shell\DartToMarkdown"

reg query "%REG_ROOT%" >nul 2>&1
if %errorlevel% neq 0 (
    echo [i] "Dart to Markdown" menu was not found (maybe not installed).
    pause
    exit /b
)

reg delete "%REG_ROOT%" /f >nul 2>&1

if %errorlevel% equ 0 (
    echo [OK] "Dart to Markdown" context menu removed successfully.
) else (
    echo [X] Something went wrong while removing the Registry key.
)

echo.
echo Restarting Explorer...
taskkill /f /im explorer.exe >nul 2>&1
start "" explorer.exe

echo.
pause
endlocal
