@echo off
chcp 65001 > nul
title TifoFlash - Push Notification Dispatcher (Apple & Android)
color 0A

echo =============================================================
echo   TifoFlash - موجه إشعارات شاشات القفل (Apple APNs & Android)
echo =============================================================
echo.

cd /d "%~dp0admin_dashboard"
node push_dispatcher.cjs

pause
