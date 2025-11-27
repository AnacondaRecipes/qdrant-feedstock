@echo off
setlocal EnableDelayedExpansion

cd /d "%SRC_DIR%"

set "PROTOC=%LIBRARY_BIN%\protoc.exe"
set "LIBCLANG_PATH=%LIBRARY_BIN%"

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
