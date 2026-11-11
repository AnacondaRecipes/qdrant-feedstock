@echo off
setlocal EnableDelayedExpansion

cd /d "%SRC_DIR%"

set "PROTOC=%LIBRARY_BIN%\protoc.exe"
set "LIBCLANG_PATH=%LIBRARY_BIN%"

rem The VS activation exports CC=cl.exe. aws-lc-sys only looks for clang-cl when CC
rem is unset, so with cl.exe the aarch64 .S sources are silently ignored and the
rem archive step fails on the missing object (LNK1181 chacha-armv8.o). Use the
rem clang-cl shipped by the `clang` build dependency on win-arm64.
if "%target_platform%"=="win-arm64" (
    set "CC=clang-cl"
    set "CXX=clang-cl"
)

cargo build --release --bin qdrant
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: cargo build failed
    exit /b 1
)

if not exist "%PREFIX%\Library\bin" mkdir "%PREFIX%\Library\bin"
copy /Y target\release\qdrant.exe "%PREFIX%\Library\bin\qdrant.exe"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to copy qdrant.exe
    exit /b 1
)
