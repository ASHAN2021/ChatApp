@echo off
title QR Chat Server - Quick Start
color 0A

echo.
echo  🚀 QR CHAT SERVER - QUICK START
echo  ═══════════════════════════════════
echo.

:: Kill any existing node processes
echo  🔄 Stopping existing servers...
taskkill /F /IM node.exe >nul 2>&1

echo  📦 Installing dependencies...
call npm install

echo.
echo  🌐 Starting Socket.IO Server on port 8000...
echo  📱 Flutter app will connect to: http://10.0.2.2:8000
echo  🖥️  Web browser can access: http://localhost:8000
echo.
echo  ✅ Server is ready! Keep this window open.
echo  ❌ To stop server: Close this window or press Ctrl+C
echo.

node server.js

pause
