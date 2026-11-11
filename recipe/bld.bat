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

rem Newer rust_win-* activation packages export CARGO_BUILD_TARGET, which moves the
rem binary to target\<triple>\release\. Resolve the real artifact directory.
set "QDRANT_BIN=target\release\qdrant.exe"
if defined CARGO_BUILD_TARGET set "QDRANT_BIN=target\%CARGO_BUILD_TARGET%\release\qdrant.exe"

if not exist "%PREFIX%\Library\bin" mkdir "%PREFIX%\Library\bin"
copy /Y "%QDRANT_BIN%" "%PREFIX%\Library\bin\qdrant.exe"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to copy %QDRANT_BIN%
    exit /b 1
)
