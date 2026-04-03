@echo off
chcp 65001 >nul 2>&1
setlocal enabledelayedexpansion

REM ============================================================
REM  编译脚本 (Windows BAT) — EXE + DLL
REM  用法: build.bat [all^|exe^|dll^|clean]
REM  默认: all
REM ============================================================

set "DIST_DIR=dist"
set "LDFLAGS=-s -w"
set "MAIN_DLL=dll\main.go"
set "MAIN_EXE=main.go"
set "MAIN_EXE_BAK=.main_exe_bak.go"
set "LOADER_C=dll\loader.c"

if "%1"=="" goto all
if "%1"=="exe" goto exe
if "%1"=="dll" goto dll
if "%1"=="clean" goto clean
goto usage

:clean
    echo [..] 清理 %DIST_DIR%
    if exist "%DIST_DIR%" rmdir /s /q "%DIST_DIR%"
    echo [OK] 已清理
    goto end

:restore_exe
    if exist "%MAIN_EXE_BAK%" (
        move /y "%MAIN_EXE_BAK%" "%MAIN_EXE%" >nul
    )
    goto :eof

:exe
    call :clean
    call :restore_exe
    mkdir "%DIST_DIR%\windows" 2>nul

    echo [..] 编译 Windows EXE (amd64)
    set CGO_ENABLED=0
    go build -trimpath -ldflags "%LDFLAGS%" -o "%DIST_DIR%\windows\fscan.exe"
    if errorlevel 1 (
        echo [FAIL] Windows EXE 编译失败
        exit /b 1
    )
    echo [OK] windows/amd64
    goto end

:dll
    call :clean
    if not exist "%MAIN_DLL%" (
        echo [FAIL] 缺少 %MAIN_DLL%
        exit /b 1
    )
    if not exist "%LOADER_C%" (
        echo [FAIL] 缺少 %LOADER_C%
        exit /b 1
    )

    REM 备份 EXE 版 main.go，替换为 DLL 版
    if exist "%MAIN_EXE%" move /y "%MAIN_EXE%" "%MAIN_EXE_BAK%" >nul
    copy /y "%MAIN_DLL%" "%MAIN_EXE%" >nul

    mkdir "%DIST_DIR%\windows-dll" 2>nul

    echo [..] 编译 Windows DLL (amd64, c-shared)
    set CGO_ENABLED=1
    go build -buildmode=c-shared -trimpath -ldflags "%LDFLAGS%" -o "%DIST_DIR%\windows-dll\fscan.dll"
    if errorlevel 1 (
        echo [FAIL] DLL 编译失败
        call :restore_exe
        exit /b 1
    )
    echo [OK] fscan.dll

    echo [..] 编译 loader.exe
    gcc -o "%DIST_DIR%\windows-dll\loader.exe" "%LOADER_C%" -s
    if errorlevel 1 (
        echo [FAIL] loader.exe 编译失败
        echo       需要 MinGW: https://www.mingw-w64.org/
        call :restore_exe
        exit /b 1
    )
    echo [OK] loader.exe

    REM 删除自动生成的 .h 文件
    del /q "%DIST_DIR%\windows-dll\fscan.h" 2>nul

    REM 恢复 EXE 版 main.go
    call :restore_exe
    goto end

:all
    call :exe
    echo.
    call :dll
    goto end

:usage
    echo 用法: %~nx0 [all^|exe^|dll^|clean]
    echo.
    echo   all   编译全部 (默认)
    echo   exe   仅编译 EXE
    echo   dll   仅编译 DLL + loader
    echo   clean 清理 dist 目录
    exit /b 1

:end
    echo.
    echo [OK] 编译完成，产物在 %DIST_DIR%\
    dir /s /b "%DIST_DIR%\*" 2>nul
    exit /b 0
