@echo off
echo ========================================
echo    Aurenna AI - Beta Deployment Script
echo ========================================
echo.
echo ✅ App signing configured with release keystore
echo 🔐 Keystore: aurenna-release-key.jks
echo.

echo 🧹 Cleaning project...
call flutter clean

echo 📦 Getting dependencies...  
call flutter pub get

echo 🔍 Running analysis...
call flutter analyze --no-fatal-warnings

echo 📋 Building for Android...
echo.
echo Choose build type:
echo 1. Debug APK (for testing)
echo 2. Release APK (for manual distribution)  
echo 3. Release AAB (for Play Store) - PROPERLY SIGNED ✅
echo.
set /p choice="Enter your choice (1-3): "

if "%choice%"=="1" (
    echo 🔨 Building debug APK...
    call flutter build apk --debug
    echo.
    echo ✅ Debug APK built successfully!
    echo 📍 Location: build\app\outputs\flutter-apk\app-debug.apk
) else if "%choice%"=="2" (
    echo 🔨 Building release APK...
    call flutter build apk --release
    echo.
    echo ✅ Release APK built successfully!
    echo 📍 Location: build\app\outputs\flutter-apk\app-release.apk
) else if "%choice%"=="3" (
    echo 🔨 Building release AAB for Play Store...
    call flutter build appbundle --release
    echo.
    echo ✅ Release AAB built successfully!
    echo 📍 Location: build\app\outputs\bundle\release\app-release.aab
    echo.
    echo 📤 Ready for Google Play Console upload!
) else (
    echo Invalid choice. Please run again.
    goto :eof
)

echo.
echo 🎉 Build completed! Check the location above for your app file.
echo.
pause