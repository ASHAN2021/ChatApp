# 📱 **Two-Device Chat Testing Guide**

## 🛠️ **Prerequisites:**

1. Flutter installed and working
2. Two Android emulators OR one emulator + one physical device
3. Socket.IO server running

## 🚀 **Step-by-Step Testing Process:**

### **Step 1: Start the Server**

```bash
# Navigate to the main project directory
cd f:\flutter\chat\ChatApp

# Start the Socket.IO server
node server.js
```

_Keep this terminal open - you'll see connection logs here_

### **Step 2: Set Up Emulators**

#### Option A: Using Flutter Commands

```bash
# List available emulators
flutter emulators

# Launch first emulator
flutter emulators --launch <emulator_name_1>

# Launch second emulator
flutter emulators --launch <emulator_name_2>
```

#### Option B: Using Android Studio

1. Open Android Studio
2. Go to **Tools > AVD Manager**
3. Start two different emulators
4. Wait for both to boot completely

### **Step 3: Check Connected Devices**

```bash
# Check all connected devices
flutter devices
```

You should see something like:

```
2 connected devices:

sdk gphone64 arm64 (mobile) • emulator-5554 • android-arm64  • Android 11 (API 30)
sdk gphone64 arm64 (mobile) • emulator-5556 • android-arm64  • Android 11 (API 30)
```

### **Step 4: Run App on Both Devices**

#### Terminal 1 (Device 1):

```bash
cd chatapp
flutter run -d emulator-5554
```

#### Terminal 2 (Device 2):

```bash
cd chatapp
flutter run -d emulator-5556
```

### **Step 5: Test Chat Functionality**

#### **Device 1 (Sender):**

1. Tap the green "Add Test Contact" button OR
2. Tap the blue "Start New Chat" button
3. Choose "Add by User ID"
4. Enter a User ID like: `device2_user`
5. Enter a name like: `Device 2`
6. Tap "Add"

#### **Device 2 (Receiver):**

1. Tap "Add by User ID"
2. Enter User ID: `device1_user`
3. Enter name: `Device 1`
4. Tap "Add"

#### **Start Chatting:**

1. On Device 1: Tap on "Device 2" chat
2. Send a message
3. On Device 2: You should see the message appear in real-time!

## 🔧 **Testing Features:**

### **1. Real-time Messaging**

- Send messages from Device 1 → Device 2
- Send messages from Device 2 → Device 1
- Check if messages appear instantly

### **2. Public Rooms**

- Both devices join the same public room (e.g., "General Chat")
- Send messages in the room
- Verify both devices receive messages

### **3. Quick Connect**

- Generate a quick connect ID on Device 1
- Use that ID on Device 2 to connect
- Test messaging

### **4. Test Chat Button**

- Use the green "Add Test Contact" button
- Verify new contacts appear in the list
- Test database functionality

## 🐛 **Troubleshooting:**

### **Server Issues:**

```bash
# Check if server is running
netstat -an | findstr :3000
```

### **Connection Issues:**

- Make sure both devices use the same server IP
- For emulators, use `10.0.2.2:3000`
- For physical devices, use your computer's IP

### **App Issues:**

```bash
# Hot reload if needed
r

# Hot restart if needed
R

# Check logs
flutter logs
```

## 📋 **Expected Results:**

✅ Messages sent from Device 1 appear on Device 2 instantly  
✅ Messages sent from Device 2 appear on Device 1 instantly  
✅ Public rooms work with multiple participants  
✅ Contact addition works correctly  
✅ Database stores chats and messages properly

## 🎯 **Test Scenarios:**

1. **Basic Chat:** Send "Hello" from Device 1 to Device 2
2. **Reverse Chat:** Reply "Hi there!" from Device 2 to Device 1
3. **Public Room:** Join "General Chat" on both devices, send messages
4. **Multiple Contacts:** Add multiple test contacts and verify they persist
5. **App Restart:** Close and reopen app, verify chats are saved

Happy Testing! 🚀
