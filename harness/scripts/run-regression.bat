@echo off
REM 回归测试体系 - 一键运行脚本（Windows）
REM 用法：
REM   scripts\run-regression.bat          REM 跑全量回归（API + E2E）
REM   scripts\run-regression.bat api      REM 只跑 API 模块测试
REM   scripts\run-regression.bat e2e      REM 只跑 E2E UI 测试
REM   scripts\run-regression.bat smoke    REM 跑冒烟测试
REM
REM 前置条件：
REM   - 后端 fat-jar 已启动（端口 8080）
REM   - 前端 Vite dev 已启动（端口 3100）
REM   - MySQL 可连接

setlocal enabledelayedexpansion

cd /d "%~dp0\.."

REM 颜色（简化版）
set "RED=[91m"
set "GREEN=[92m"
set "YELLOW=[93m"
set "NC=[0m"

set "MODE=%~1"
if "%MODE%"=="" set "MODE=all"

echo %YELLOW%=== 回归测试体系（harness v1.0）===
echo 模式: %MODE%
echo 后端: http://localhost:8080/jeecg-boot
echo 前端: http://localhost:3100
echo.

REM 跑 API 测试
:run_api
echo %YELLOW%=== 跑 API 模块测试 ===
set "PASSED=0"
set "FAILED=0"
for %%f in (tests\modules\basic-*.test.js) do (
    echo   ▶ %%~nxf
    node "%%f" >nul 2>&1
    if !errorlevel! equ 0 (
        set /a PASSED+=1
        echo     PASSED
    ) else (
        set /a FAILED+=1
        echo     FAILED
    )
)
echo.
echo API: %PASSED% passed / %FAILED% failed
if %FAILED% gtr 0 exit /b 1
goto :eof

REM 跑 E2E 测试
:run_e2e
echo %YELLOW%=== 跑 E2E UI 测试 ===
if not exist "node_modules\@playwright" (
    echo   安装 playwright 依赖...
    call npm install --no-audit --no-fund >nul 2>&1
)
call npx playwright test e2e\mes\basic-*.spec.ts --config e2e\playwright.config.ts --reporter=list --retries=1 --timeout=60000
goto :eof

REM 跑冒烟
:run_smoke
echo %YELLOW%=== 冒烟测试 ===
if not exist "node_modules\@playwright" (
    call npm install --no-audit --no-fund >nul 2>&1
)
call npx playwright test e2e\smoke\ --config e2e\playwright.config.ts --reporter=list
goto :eof

REM 分发
if /i "%MODE%"=="api" goto :run_api
if /i "%MODE%"=="e2e" goto :run_e2e
if /i "%MODE%"=="smoke" goto :run_smoke
if /i "%MODE%"=="all" (
    call :run_api
    call :run_e2e
) else (
    echo 用法: %~nx0 [api^|e2e^|smoke^|all]
    exit /b 1
)

echo.
if %ERRORLEVEL% equ 0 (
    echo %GREEN%✅ 全部通过%NC%
) else (
    echo %RED%❌ 有失败%NC%
    exit /b 1
)