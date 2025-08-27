@echo off
echo Starting Chat App Testing Environment
echo =====================================
echo.

echo Step 1: Starting Socket.IO Server...
start "Socket.IO Server" cmd /k "node server.js"
echo Server started in new window.
echo.

echo Step 2: Instructions for testing with two emulators:
echo.
echo 1. Open Android Studio
echo 2. Go to Tools > AVD Manager
echo 3. Create/Start two different emulators (different names)
echo 4. Or use: flutter emulators --launch [emulator_name]
echo.
echo Step 3: Run the app on both emulators:
echo.
echo Terminal 1: flutter run -d [device1_id]
echo Terminal 2: flutter run -d [device2_id]
echo.
echo Step 4: Test the chat functionality:
echo - Add contacts by User ID
echo - Send messages between devices
echo - Test real-time messaging
echo.

pause
