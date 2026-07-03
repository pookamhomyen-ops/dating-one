@echo off
setlocal EnableDelayedExpansion
chcp 65001 >nul

if "%~1"=="" exit /b 1

set "INPUT_FILE=%~1"
set "INPUT_DIR=%~dp1"
set "INPUT_NAME=%~n1"
set "OUTPUT_FILE=%INPUT_DIR%%INPUT_NAME%.md"

if not exist "%INPUT_FILE%" exit /b 1

:: สร้างไฟล์ .md เริ่มต้นด้วยชื่อไฟล์
> "%OUTPUT_FILE%" echo # %INPUT_NAME%.dart
>> "%OUTPUT_FILE%" echo.
>> "%OUTPUT_FILE%" echo ```dart

:: อ่านไฟล์ .dart ทีละบรรทัด ลบ Comment และบรรทัดว่าง เพื่อประหยัด Token ขั้นสุด
for /f "usebackq delims=" %%A in ("%INPUT_FILE%") do (
    set "line=%%A"
    
    :: ลบช่องว่างส่วนเกินด้านหน้าชั่วคราวเพื่อเช็คว่าเป็น Comment ไหม
    set "test_line=!line: =!"
    
    :: 1. ข้ามบรรทัดว่าง
    if not "!test_line!"=="" (
        :: 2. ข้ามบรรทัดที่เป็น Comment แบบ // (แต่ไม่รวมพวก http://)
        if not "!test_line:~0,2!"=="//" (
            :: พิมพ์โค้ดที่สะอาดแล้วลงไฟล์ .md
            >> "%OUTPUT_FILE%" echo !line!
        )
    )
)

>> "%OUTPUT_FILE%" echo ```
endlocal