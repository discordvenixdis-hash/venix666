@echo off
setlocal enabledelayedexpansion

if "%~1"=="" (
    echo [ERROR] Usage: inject.bat ^<packageName^>
    echo Example: inject.bat com.supercell.clashroyale
    exit /b 1
)

set PACKAGE_NAME=%~1
set DEVICE=127.0.0.1:5555
set SU_PATH=/boot/android/android/system/xbin/bstk/su
set SD_CACHE=/sdcard/.cache
set DATA_LOCAL=/data/local
set INJECTOR_NAME=injectionlib
set LIB_NAME=libindia.so
set INJECTOR_LOCAL=C:\Windows\injectionlib
set LIB_LOCAL=C:\Windows\libindia.so

echo  Target: %PACKAGE_NAME%
echo ============================================================

set ADB="C:\Program Files\BlueStacks_nxt\HD-Adb.exe"

echo [1/7] Connecting to %DEVICE%...
%ADB% connect %DEVICE%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to connect to %DEVICE%
    exit /b 1
)
timeout /t 1 /nobreak >nul

echo [*] Forwarding port 21405...
%ADB% -s %DEVICE% forward tcp:21405 tcp:21405
if %errorlevel% neq 0 (
    echo [WARN] Port forward failed
)

echo [2/7] Cleaning old files and logs from device...
%ADB% -s %DEVICE% logcat -c
%ADB% -s %DEVICE% shell "%SU_PATH% -c 'rm -f %DATA_LOCAL%/%INJECTOR_NAME% %DATA_LOCAL%/%LIB_NAME%'"
%ADB% -s %DEVICE% shell "rm -f %SD_CACHE%/%INJECTOR_NAME% %SD_CACHE%/%LIB_NAME%"
timeout /t 1 /nobreak >nul

echo [3/7] Creating staging directory...
%ADB% -s %DEVICE% shell "mkdir -p %SD_CACHE%"
timeout /t 1 /nobreak >nul

echo [4/7] Pushing injector and library...
%ADB% -s %DEVICE% push "%INJECTOR_LOCAL%" %SD_CACHE%/%INJECTOR_NAME%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push injector
    exit /b 1
)
%ADB% -s %DEVICE% push "%LIB_LOCAL%" %SD_CACHE%/%LIB_NAME%
if %errorlevel% neq 0 (
    echo [ERROR] Failed to push library
    exit /b 1
)
timeout /t 1 /nobreak >nul

echo [5/7] Moving files to %DATA_LOCAL%...
%ADB% -s %DEVICE% shell "%SU_PATH% -c 'mv %SD_CACHE%/%INJECTOR_NAME% %DATA_LOCAL%/%INJECTOR_NAME% && mv %SD_CACHE%/%LIB_NAME% %DATA_LOCAL%/%LIB_NAME%'"
if %errorlevel% neq 0 (
    echo [ERROR] Failed to move files
    exit /b 1
)
timeout /t 1 /nobreak >nul

echo [6/7] Injecting %LIB_NAME% into %PACKAGE_NAME%...
%ADB% -s %DEVICE% shell "%SU_PATH% -c 'chmod 777 %DATA_LOCAL%/%INJECTOR_NAME% %DATA_LOCAL%/%LIB_NAME% && %DATA_LOCAL%/%INJECTOR_NAME% -pkg %PACKAGE_NAME% -lib %DATA_LOCAL%/%LIB_NAME% -no-entry -v'"
if %errorlevel% neq 0 (
    echo [ERROR] Injection failed
    exit /b 1
)
echo [ OK ] Injection completed successfully.
timeout /t 2 /nobreak >nul

echo [7/7] Cleaning up...
%ADB% -s %DEVICE% shell "%SU_PATH% -c 'rm -f %DATA_LOCAL%/%INJECTOR_NAME% %DATA_LOCAL%/%LIB_NAME%'"
%ADB% -s %DEVICE% shell "rm -f %SD_CACHE%/%INJECTOR_NAME% %SD_CACHE%/%LIB_NAME%"
echo [ OK ] Cleanup done.

echo Waiting 5s for library to log...
timeout /t 5 /nobreak >nul

echo.
echo ============================================================
echo  LOGCAT OUTPUT (VASTCLIENT):
echo ============================================================
echo.
echo  [D] Dump once  [L] Live monitor (Ctrl+C to stop)
choice /c DL /n /m "Press D or L: "
if errorlevel 2 goto LIVE
if errorlevel 1 goto DUMP

:DUMP
%ADB% -s %DEVICE% logcat -d -s VASTCLIENT
goto DONE

:LIVE
echo ============================================================
echo  Live monitor started — press Ctrl+C to stop
echo ============================================================
%ADB% -s %DEVICE% logcat -c
%ADB% -s %DEVICE% logcat -s VASTCLIENT

:DONE
echo ============================================================
echo  Done. %LIB_NAME% injected into %PACKAGE_NAME%.
echo ============================================================
endlocal
