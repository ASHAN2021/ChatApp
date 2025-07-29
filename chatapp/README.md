# QR Chat App

A Flutter mobile application that enables instant chat connections between users through QR code scanning. No phone numbers or contact exchanges required!

## Features

### Core Functionality ✨

- **Welcome Screen**: Beautiful onboarding with app introduction
- **Profile Setup**: Simple name-based profile creation
- **QR Code Generation**: Unique QR codes for each user
- **QR Code Scanning**: Camera-based QR code detection
- **Instant Chat**: Real-time messaging interface
- **Message Persistence**: SQLite database for chat history
- **Bottom Navigation**: 4-tab interface (Home, Chats, Scan, Profile)

### Technical Features 🔧

- **Local Database**: SQLite for message and chat storage
- **QR Technology**: Generate and scan QR codes
- **Camera Integration**: Camera permissions and controls
- **Responsive UI**: Material Design with custom theming
- **Error Handling**: Comprehensive exception handling
- **Notifications**: Toast messages for user feedback

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── Model/                    # Data models
│   ├── user_model.dart      # User data structure
│   ├── chat_model.dart      # Chat data structure
│   └── message_model.dart   # Message data structure
├── Services/                 # Business logic services
│   ├── database_service.dart    # SQLite database operations
│   ├── qr_service.dart         # QR code generation/processing
│   ├── notification_service.dart # Toast notifications
│   └── sample_data.dart        # Sample data for testing
├── Screens/                  # Main application screens
│   ├── welcome_screen.dart     # Welcome/onboarding screen
│   ├── profile_setup_screen.dart # Profile creation
│   ├── main_screen.dart        # Bottom navigation container
│   ├── home_tab.dart          # Home tab with app info
│   ├── chat_tab.dart          # Chat list
│   ├── scan_tab.dart          # QR scanner
│   ├── profile_tab.dart       # User profile & QR display
│   └── chat_page.dart         # Individual chat interface
└── CustomUI/                 # Custom UI components
    ├── own_message_card.dart  # Sent message bubble
    └── reply_card.dart        # Received message bubble
```

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  flutter_svg: ^2.1.0
  emoji_picker_flutter: ^4.3.0
  shared_preferences: ^2.5.3
  camera: ^0.11.1
  path_provider: ^2.1.5
  path: ^1.9.1
  video_player: ^2.9.5
  socket_io_client: ^2.0.3+1
  otp_text_field: ^1.1.3
  image_picker: ^1.1.2
  permission_handler: ^12.0.0+1
  http: ^1.4.0
  qr_flutter: ^4.1.0 # QR code generation
  qr_code_scanner: ^1.0.1 # QR code scanning
  sqflite: ^2.4.1 # SQLite database
  intl: ^0.19.0 # Date formatting
  uuid: ^4.5.1 # Unique ID generation
```

## Setup Instructions

1. **Clone the repository**

   ```bash
   git clone <repository-url>
   cd ChatApp/chatapp
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Run the application**
   ```bash
   flutter run
   ```

## App Flow

### 1. Welcome Screen 🎉

- Beautiful gradient background
- App features overview
- "Get Started" button to proceed

### 2. Profile Setup 👤

- Enter user name
- Creates unique user ID and QR code
- Saves profile to local database

### 3. Main Screen (4 Tabs) 📱

#### Home Tab 🏠

- App description and features
- How-to-use instructions
- Quick scan button

#### Chat Tab 💬

- List of active chats
- Last message preview
- Swipe to delete functionality
- Empty state with scan prompt

#### Scan Tab 📱

- Camera-based QR scanner
- Permission handling
- Flash and camera flip controls
- Real-time QR code detection

#### Profile Tab 👤

- User information display
- Personal QR code generation
- Profile management options
- Reset/clear functionality

### 4. Chat Page 💭

- Real-time messaging interface
- Message bubbles (sent/received)
- Timestamp display
- Message persistence
- Chat options menu

## Key Features Explained

### QR Code Connection Process

1. **User A** opens Profile tab and displays their QR code
2. **User B** opens Scan tab and scans User A's QR code
3. **System** automatically creates a chat session
4. **Both users** can now exchange messages
5. **Chat history** is saved locally on both devices

### Database Schema

- **Users Table**: id, name, profileImage, qrCode, createdAt
- **Chats Table**: id, name, lastMessage, lastMessageTime, profileImage, isOnline
- **Messages Table**: id, chatId, senderId, message, timestamp, isMe, isRead, messageType, path

### Security & Privacy

- All data stored locally (SQLite)
- No server-side data storage
- Temporary connections
- User consent required for continued chat

## Permissions Required

- **Camera**: For QR code scanning
- **Storage**: For local database and file operations

## Testing the App

1. **Install on two devices** or use emulator + physical device
2. **Setup profiles** on both devices
3. **Generate QR code** on device 1 (Profile tab)
4. **Scan QR code** on device 2 (Scan tab)
5. **Start chatting** - messages will appear on both devices

## Future Enhancements

- [ ] Real-time sync between devices (WebSocket)
- [ ] Group chat support
- [ ] File/image sharing
- [ ] Chat encryption
- [ ] User status indicators
- [ ] Message reactions
- [ ] Chat themes
- [ ] Export chat history
- [ ] Push notifications

## Troubleshooting

### Common Issues

1. **Camera Permission Denied**

   - Go to Settings > Apps > QR Chat > Permissions
   - Enable Camera permission

2. **QR Code Not Scanning**

   - Ensure good lighting
   - Hold steady and at proper distance
   - Try using flash option

3. **App Crashes on Startup**
   - Clear app data and restart
   - Reinstall the application

## Technical Notes

- **Flutter Version**: 3.8.0+
- **Minimum SDK**: Android 21, iOS 11
- **Database**: SQLite with sqflite package
- **State Management**: setState (can be upgraded to Provider/Bloc)
- **Architecture**: MVC pattern with Services layer

## Contributing

1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## License

This project is for educational purposes. Please refer to the LICENSE file for details.

---

**Note**: This app demonstrates QR code-based instant messaging. For production use, additional security measures and backend infrastructure would be recommended.
