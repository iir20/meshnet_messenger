@echo off
echo ===== Building MeshNet Messenger APK =====
echo.

REM Ensure Flutter is in the path
set FLUTTER_PATH=C:\flutter\bin

echo Cleaning previous builds...
call %FLUTTER_PATH%\flutter.bat clean

echo.
echo Running Flutter pub get...
call %FLUTTER_PATH%\flutter.bat pub get

echo.
echo Building APK...
call %FLUTTER_PATH%\flutter.bat build apk --release

echo.
if %ERRORLEVEL% EQU 0 (
    echo Build successful!
    echo APK location: build\app\outputs\flutter-apk\app-release.apk
    
    REM Display APK information
    echo.
    echo APK Information:
    echo -----------------------------
    echo Name: Meshaging
    echo Version: 1.0.0+1
    echo Size: ~20MB
    echo Requirements: Android 5.0+ (API 21+)
    echo Features:
    echo  - Orbital Chat List
    echo  - Encrypted Messaging
    echo  - HoloRings Story System
    echo  - Shadow Clone AI
    echo  - Mood-Aware UI
    echo  - Haptic Feedback
) else (
    echo Build failed with error level %ERRORLEVEL%
)

echo.
echo ===== Build Process Complete =====
pause 