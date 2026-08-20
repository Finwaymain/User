@echo off
echo =================================================
echo  Fiinway USER APP - Safe Build Script
echo =================================================
echo [1/4] Killing stale dart and java processes...
taskkill /F /IM dart.exe 2>nul
taskkill /F /IM java.exe 2>nul
timeout /t 2 /nobreak >nul
echo [2/4] Setting Dart VM heap options...
set DART_VM_OPTIONS=--old-gen-heap-size=3096
set FLUTTER_TOOL_ARGS=--old-gen-heap-size=3096
echo [3/4] Cleaning build artifacts...
call D:\src\flutter\bin\flutter.bat clean
echo [4/4] Building debug APK...
call D:\src\flutter\bin\flutter.bat build apk --debug --no-tree-shake-icons
echo =================================================
echo  Build complete!
echo =================================================
pause
