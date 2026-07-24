@echo off
:: Cấu hình UTF-8 để hiển thị tiếng Việt có dấu
chcp 65001 > nul
title HistoryTalk Android Build Script

echo =======================================================
echo        HISTORYTALK ANDROID BUILD TOOL
echo =======================================================
echo.
echo Vui lòng chọn loại file bạn muốn build:
echo [1] Build APK Debug (Bản thử nghiệm nhanh)
echo [2] Build APK Release (Bản chạy chính thức)
echo [3] Build Android App Bundle (AAB - Để upload CH Play)
echo [4] Thoát
echo.

set /p choice="Nhập lựa chọn của bạn (1-4): "

if "%choice%"=="1" goto build_debug
if "%choice%"=="2" goto build_release
if "%choice%"=="3" goto build_aab
if "%choice%"=="4" goto end
goto invalid

:build_debug
echo.
echo [1/3] Đang dọn dẹp các bản build cũ (flutter clean)...
call flutter clean
echo.
echo [2/3] Đang tải các gói thư viện (flutter pub get)...
call flutter pub get
echo.
echo [3/3] Đang build APK dạng Debug...
call flutter build apk --debug
echo.
echo =======================================================
echo BUILD THÀNH CÔNG!
echo File cài đặt APK nằm tại:
echo build\app\outputs\flutter-apk\app-debug.apk
echo =======================================================
goto end_success

:build_release
echo.
echo [1/3] Đang dọn dẹp các bản build cũ (flutter clean)...
call flutter clean
echo.
echo [2/3] Đang tải các gói thư viện (flutter pub get)...
call flutter pub get
echo.
echo [3/3] Đang build APK dạng Release...
call flutter build apk --release
echo.
echo =======================================================
echo BUILD THÀNH CÔNG!
echo File cài đặt APK nằm tại:
echo build\app\outputs\flutter-apk\app-release.apk
echo =======================================================
goto end_success

:build_aab
echo.
echo [1/3] Đang dọn dẹp các bản build cũ (flutter clean)...
call flutter clean
echo.
echo [2/3] Đang tải các gói thư viện (flutter pub get)...
call flutter pub get
echo.
echo [3/3] Đang build Android App Bundle (AAB)...
call flutter build appbundle --release
echo.
echo =======================================================
echo BUILD THÀNH CÔNG!
echo File App Bundle nằm tại:
echo build\app\outputs\bundle\release\app-release.aab
echo =======================================================
goto end_success

:invalid
echo Lựa chọn không hợp lệ. Vui lòng chạy lại script!
goto end

:end_success
explorer build\app\outputs\

:end
pause
