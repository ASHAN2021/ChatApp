@echo off
echo Adding Windows Firewall rule for Socket.IO server...
netsh advfirewall firewall add rule name="ChatApp Socket.IO Server" dir=in action=allow protocol=TCP localport=8000
echo.
echo Firewall rule added successfully!
echo Your server is now accessible from other devices on the network.
echo.
echo Server addresses for different devices:
echo   Android Emulator: http://10.0.2.2:8000
echo   Physical Device: http://192.168.8.123:8000 or http://192.168.56.1:8000
echo.
pause
