@echo off
title Chat App Server
color 0B

echo.
echo  🚀 STARTING CHAT APP SERVER
echo  ═══════════════════════════════════
echo.

echo  📦 Installing dependencies (if needed)...
npm install

echo.
echo  🌐 Starting Socket.IO Server on port 3000...
echo  Press Ctrl+C to stop the server
echo.

node server.js
