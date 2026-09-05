@echo off
chcp 65001 > nul
title TifoFlash Push Dispatcher
color 0A

echo =============================================================
echo   TifoFlash - موجه إشعارات شاشات القفل
echo =============================================================
echo.

cd /d "%~dp0admin_dashboard"
node push_dispatcher.cjs

pause
