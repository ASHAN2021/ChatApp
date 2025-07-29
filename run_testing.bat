@echo off
title Chat App - Two Device Testing
color 0A

echo.
echo  ╔══════════════════════════════════════════════════════════════════╗
echo  ║                    CHAT APP TWO-DEVICE TESTING                  ║  
echo  ╚══════════════════════════════════════════════════════════════════╝
echo.

echo  📱 STEP 1: Installing Dependencies
echo  ═══════════════════════════════════
echo  Installing Node.js dependencies...
npm install
echo  Installing Flutter dependencies...
cd chatapp
call flutter pub get
cd ..
echo  ✅ Dependencies installed!
echo.

echo  🚀 STEP 2: Check Available Devices  
echo  ═══════════════════════════════════
call flutter devices
echo.

echo  📋 STEP 3: Commands to Run in Separate Terminals
echo  ═══════════════════════════════════════════════════
echo.
echo  Terminal 1 - Start Server:
echo  ┌─────────────────────────────────────────────────────────────────┐
echo  │ cd f:\flutter\chat\ChatApp                                      │
echo  │ node server.js                                                  │
echo  └─────────────────────────────────────────────────────────────────┘
echo.
echo  Terminal 2 - Device 1:
echo  ┌─────────────────────────────────────────────────────────────────┐
echo  │ cd f:\flutter\chat\ChatApp\chatapp                              │
echo  │ flutter run -d emulator-5554                                    │
echo  └─────────────────────────────────────────────────────────────────┘
echo.
echo  Terminal 3 - Device 2:
echo  ┌─────────────────────────────────────────────────────────────────┐
echo  │ cd f:\flutter\chat\ChatApp\chatapp                              │
echo  │ flutter run -d emulator-5556                                    │
echo  └─────────────────────────────────────────────────────────────────┘
echo.

echo  🎯 STEP 4: Testing Instructions
echo  ═══════════════════════════════════
echo.
echo  1. Start the server first (Terminal 1)
echo  2. Wait for "Server listening on port 3000" message
echo  3. Run the app on Device 1 (Terminal 2)
echo  4. Run the app on Device 2 (Terminal 3)
echo  5. On Device 1: Add contact with ID "device2_user"
echo  6. On Device 2: Add contact with ID "device1_user"  
echo  7. Start chatting between devices!
echo.

echo  💡 TIP: Replace emulator-5554 and emulator-5556 with your actual device IDs
echo      from the 'flutter devices' output above.
echo.

set /p choice="Press ENTER to continue, or type 'server' to start server now: "

if /i "%choice%"=="server" (
    echo.
    echo  🚀 Starting Socket.IO Server...
    cd ..
    node server.js
) else (
    echo.
    echo  📖 See TESTING_GUIDE.md for detailed instructions!
    echo  👋 Happy testing!
)

pause
