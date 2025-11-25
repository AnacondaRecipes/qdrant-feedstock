@echo off
setlocal EnableDelayedExpansion

cd /d "%SRC_DIR%"

REM Set PROTOC so prost-build can find protoc
REM On Windows, protoc might be in different locations
where protoc >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    for /f "delims=" %%i in ('where protoc') do (
        set "PROTOC=%%i"
        goto :protoc_found
    )
)

REM Try common conda locations
if exist "%PREFIX%\Library\bin\protoc.exe" (
    set "PROTOC=%PREFIX%\Library\bin\protoc.exe"
    goto :protoc_found
)
if exist "%BUILD_PREFIX%\Library\bin\protoc.exe" (
    set "PROTOC=%BUILD_PREFIX%\Library\bin\protoc.exe"
    goto :protoc_found
)
if exist "%LIBRARY_BIN%\protoc.exe" (
    set "PROTOC=%LIBRARY_BIN%\protoc.exe"
    goto :protoc_found
)

echo ERROR: protoc not found. Please ensure protobuf-compiler is installed.
exit /b 1

:protoc_found
set "PROTOC=%PROTOC%"
echo Using protoc: %PROTOC%

REM Set LIBCLANG_PATH so bindgen can find libclang.dll
REM libclang package installs libclang.dll in Library\bin
if exist "%BUILD_PREFIX%\Library\bin\libclang.dll" (
    set "LIBCLANG_PATH=%BUILD_PREFIX%\Library\bin"
    goto :libclang_found
)
if exist "%PREFIX%\Library\bin\libclang.dll" (
    set "LIBCLANG_PATH=%PREFIX%\Library\bin"
    goto :libclang_found
)
if exist "%LIBRARY_BIN%\libclang.dll" (
    set "LIBCLANG_PATH=%LIBRARY_BIN%"
    goto :libclang_found
)

echo ERROR: Could not find libclang.dll. Please ensure libclang package is installed.
echo Searched in: %BUILD_PREFIX%\Library\bin, %PREFIX%\Library\bin, %LIBRARY_BIN%
exit /b 1

:libclang_found
echo Using LIBCLANG_PATH: !LIBCLANG_PATH!
set "LIBCLANG_PATH=!LIBCLANG_PATH!"

REM On Windows with MSVC, the build.rs script handles architecture flags automatically
REM It uses /arch:AVX, /arch:AVX2, etc. for MSVC compiler
REM No need to modify CFLAGS/CXXFLAGS like on Linux/Mac

cargo build --release --bin qdrant
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: cargo build failed
    exit /b 1
)

REM Create bin directory if it doesn't exist
if not exist "%PREFIX%\Library\bin" mkdir "%PREFIX%\Library\bin"

REM Copy the built executable
copy /Y target\release\qdrant.exe "%PREFIX%\Library\bin\qdrant.exe"
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Failed to copy qdrant.exe
    exit /b 1
)

echo Build completed successfully!
