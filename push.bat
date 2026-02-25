@echo off
:: Set code page to UTF-8
chcp 65001 >nul

echo ==========================================
echo    PPanel One-Click Push System
echo ==========================================

set "PARENT_DIR=%~dp0..\"

:: 1. Push Web
echo.
echo [1/2] Processing Web (ppanel-web)...
cd /d "%PARENT_DIR%ppanel-web"
if exist ".git" (
    git add .
    git commit -m "auto push from windows script"
    git push origin main
    if %errorlevel% equ 0 (
        echo ^>^> Web push successful!
    ) else (
        echo ^>^> Web push failed.
    )
) else (
    echo ^>^> Error: .git not found in ppanel-web at %cd%.
)

:: 2. Push Server
echo.
echo [2/3] Processing Server (ppanel-server)...
cd /d "%PARENT_DIR%ppanel-server"
if exist ".git" (
    git add .
    git commit -m "auto push from windows script"
    git push origin main
    if %errorlevel% equ 0 (
        echo ^>^> Server push successful!
    ) else (
        echo ^>^> Server push failed.
    )
) else (
    echo ^>^> Error: .git not found in ppanel-server at %cd%.
)

:: 3. Push Deploy (Current Repo)
echo.
echo [3/3] Processing Deploy (ppanel-deploy)...
cd /d "%~dp0"
if exist ".git" (
    git add .
    git commit -m "auto push from windows script"
    git push origin main
    if %errorlevel% equ 0 (
        echo ^>^> Deploy push successful!
    ) else (
        echo ^>^> Deploy push failed.
    )
) else (
    echo ^>^> Error: .git not found in ppanel-deploy at %cd%.
)

echo.
echo ==========================================
echo All tasks completed!
echo ==========================================
pause
