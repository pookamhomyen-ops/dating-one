@echo off
chcp 65001 >nul
echo ========================================
echo   Soulive - Push to GitHub
echo ========================================
echo.

cd /d D:\Weerawat\project-dating-one

:: --- กำหนดเฉพาะไฟล์/โฟลเดอร์ที่จำเป็น ---
git add pubspec.yaml
git add pubspec.lock
git add lib/
git add android/app/src/main/AndroidManifest.xml
git add android/app/build.gradle.kts
git add android/build.gradle.kts
git add android/settings.gradle.kts
git add android/gradle.properties
git add android/gradle/wrapper/gradle-wrapper.properties
git add assets/

:: --- ข้อความ commit ---
set /p MSG="กรอก commit message (กด Enter เพื่อใช้ค่า default): "
if "%MSG%"=="" set MSG=update project files

git commit -m "%MSG%"
git push origin main

echo.
echo ========================================
echo   Push สำเร็จแล้ว!
echo ========================================
pause