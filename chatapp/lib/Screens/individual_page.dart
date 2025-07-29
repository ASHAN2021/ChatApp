import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:chatapp/CustomUI/own_file_card.dart';
import 'package:chatapp/CustomUI/own_message_card.dart';
import 'package:chatapp/CustomUI/reply_file_card.dart';
import 'package:chatapp/CustomUI/reply_message.dart';
import 'package:chatapp/Model/chat_model.dart';
import 'package:chatapp/Model/message_model.dart';
import 'package:chatapp/Screens/camera_screen.dart';
import 'package:chatapp/Screens/camera_view.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class IndividualPage extends StatefulWidget {
  const IndividualPage({super.key, this.chatModel, this.sourceChat});

  final ChatModel? chatModel;
  final ChatModel? sourceChat;
  @override
  State<IndividualPage> createState() => _IndividualPageState();
}

class _IndividualPageState extends State<IndividualPage> {
  bool isEmojiVisible = false;
  FocusNode textFieldFocusNode = FocusNode();
  late IO.Socket socket;
  bool isSocketConnected = false;
  TextEditingController textFieldController = TextEditingController();
  bool sendButton = false;
  List<MessageModel> messages = [];
  ImagePicker _picker = ImagePicker();
  XFile? file;
  int popTime = 0;
  Timer? _refreshTimer;
  Timer? _messageCheckTimer;
  String lastMessageId = "";

  @override
  void initState() {
    super.initState();
    loadMessageHistory();
    connect();
    _startAutoRefresh();

    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        setState(() {
          isEmojiVisible = false;
        });
      }
    });
  }

  void _startAutoRefresh() {
    // Auto-refresh messages every 1 second
    _refreshTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (mounted && !isSocketConnected) {
        // Only refresh from API if socket is not connected
        _refreshMessages();
      }
    });

    // Check for real-time message updates every 500ms when socket is connected
    _messageCheckTimer = Timer.periodic(Duration(milliseconds: 500), (timer) {
      if (mounted && isSocketConnected) {
        // Socket is handling real-time updates, just ensure UI is current
        _checkForNewMessages();
      }
    });
  }

  Future<void> _refreshMessages() async {
    try {
      await loadMessageHistory();
    } catch (e) {
      print("❌ Error during auto-refresh: $e");
    }
  }

  void _checkForNewMessages() {
    // This method ensures UI stays responsive and checks for any missed updates
    if (messages.isNotEmpty) {
      String currentLastId = messages.last.id;
      if (currentLastId != lastMessageId) {
        lastMessageId = currentLastId;
        // Scroll to bottom when new message is detected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });
      }
    }
  }

  void _scrollToBottom() {
    // Implementation depends on your scroll controller setup
    // This is a placeholder for scroll-to-bottom functionality
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _messageCheckTimer?.cancel();
    socket.dispose();
    textFieldController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  Future<void> loadMessageHistory() async {
    if (widget.sourceChat?.id == null || widget.chatModel?.id == null) {
      print("❌ Invalid user IDs for loading messages");
      return;
    }

    try {
      print("🔄 Loading message history...");

      // Try multiple server addresses
      List<String> serverAddresses = [
        "http://10.0.2.2:8000", // Android emulator
        "http://localhost:8000", // iOS simulator
        "http://127.0.0.1:8000", // Localhost
        "http://192.168.1.5:8000", // Current Wi-Fi IP
        "http://192.168.2.1:8000", // Alternative IP
      ];

      http.Response? response;

      for (String url in serverAddresses) {
        try {
          print("🔄 Trying to load messages from: $url");
          response = await http
              .get(
                Uri.parse(
                  "$url/api/messages/${widget.sourceChat!.id}/${widget.chatModel!.id}",
                ),
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(Duration(seconds: 5));

          if (response.statusCode == 200) {
            print("✅ Successfully loaded messages from: $url");
            break;
          }
        } catch (e) {
          print("❌ Failed to load messages from $url: $e");
          continue;
        }
      }

      if (response != null && response.statusCode == 200) {
        final List<dynamic> messageData = json.decode(response.body);

        for (var msg in messageData) {
          String messageType = msg['sourceId'] == widget.sourceChat?.id
              ? "source"
              : "destination";
          setMessage(messageType, msg['message'] ?? '', msg['path'] ?? '');
        }

        print("📨 Loaded ${messageData.length} messages");
      } else {
        print("❌ Failed to load message history");
      }
    } catch (e) {
      print("❌ Error loading message history: $e");
    }
  }

  void connect() {
    print("🔄 Initializing socket connection...");

    // Try different addresses based on device type
    _connectWithFallback();
  }

  void _connectWithFallback() {
    print("🔍 Detecting device type for optimal connection...");
    print("🔍 Source Chat ID: ${widget.sourceChat?.id}");
    print("🔍 Target Chat ID: ${widget.chatModel?.id}");

    // Detect if running on emulator by checking for specific emulator characteristics
    bool isEmulator =
        Platform.isAndroid &&
        (Platform.environment['ANDROID_DATA']?.contains('emulator') == true ||
            Platform.environment['FLUTTER_TEST'] == 'true');

    print(
      "🤖 Device type detected: ${isEmulator ? 'Android Emulator' : 'Physical Device'}",
    );

    // Reorder addresses based on device type for better success rate
    List<String> serverAddresses;

    if (isEmulator) {
      // For emulator, prioritize emulator-specific addresses
      serverAddresses = [
        "http://10.0.2.2:8000", // Primary emulator address
        "http://127.0.0.1:8000", // Loopback
        "http://localhost:8000", // Localhost
        "http://192.168.1.5:8000", // Current Wi-Fi IP
        "http://192.168.2.1:8000", // Alternative IP
      ];
    } else {
      // For physical devices, prioritize network addresses
      serverAddresses = [
        "http://192.168.1.5:8000", // Current Wi-Fi IP (best for physical devices)
        "http://192.168.2.1:8000", // Alternative IP
        "http://10.0.2.2:8000", // Emulator address (fallback)
        "http://localhost:8000", // Localhost
        "http://127.0.0.1:8000", // Loopback
      ];
    }

    print(
      "🌐 Will try addresses in this order for ${isEmulator ? 'emulator' : 'physical device'}:",
    );
    for (int i = 0; i < serverAddresses.length; i++) {
      print("   ${i + 1}. ${serverAddresses[i]}");
    }

    _tryConnectToAddress(serverAddresses, 0);
  }

  void _tryConnectToAddress(List<String> addresses, int index) {
    if (index >= addresses.length) {
      print("❌ All connection attempts failed");
      print(
        "💡 Suggestion: Check if server is running and firewall allows port 8000",
      );
      setState(() {
        isSocketConnected = false;
      });
      return;
    }

    String address = addresses[index];
    print(
      "🔄 Attempting connection ${index + 1}/${addresses.length} to: $address",
    );

    socket = IO.io(
      address,
      IO.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Add polling as fallback
          .enableForceNew()
          .enableAutoConnect()
          .setTimeout(20000) // 20 seconds timeout per attempt
          .setReconnectionAttempts(3) // More attempts for each address
          .setReconnectionDelay(1000) // Faster retry
          .build(),
    );

    socket.onConnect((_) {
      print("✅ Socket connected with ID: ${socket.id} to $address");
      print("📝 Signing in with sourceId: ${widget.sourceChat?.id}");
      print("🎯 Target will be: ${widget.chatModel?.id}");
      setState(() {
        isSocketConnected = true;
      });
      socket.emit("signin", widget.sourceChat?.id);
    });

    // Set up message listener outside of onConnect to avoid multiple registrations
    socket.on("message", (msg) {
      print("📨 Real-time message received: $msg");
      try {
        if (msg != null && msg['message'] != null) {
          print("✅ Processing real-time message: ${msg['message']}");
          // Add message to UI immediately for real-time update
          _addIncomingMessage(msg);
        } else {
          print("❌ Invalid message format received");
        }
      } catch (e) {
        print("❌ Error processing real-time message: $e");
      }
    });

    // Listen for message sent confirmation
    socket.on("messageSent", (data) {
      print("✅ Message sent confirmation received: $data");
      _handleMessageSentConfirmation(data);
    });

    // Listen for message delivery confirmation
    socket.on("messageDelivered", (data) {
      print("📬 Message delivered: $data");
      _handleMessageDelivered(data);
    });

    // Listen for message pending (user offline)
    socket.on("messagePending", (data) {
      print("⏳ Message pending: $data");
      _handleMessagePending(data);
    });

    // Listen for typing indicators
    socket.on("typing", (data) {
      print("⌨️ Typing indicator: $data");
      if (data['userId'] == widget.chatModel?.id) {
        setState(() {
          // Handle typing indicator in UI
        });
      }
    });

    // Listen for user activity
    socket.on("userActivity", (data) {
      print("👥 User activity: $data");
      if (data['userId'] == widget.chatModel?.id) {
        setState(() {
          // Update user activity status
        });
      }
    });

    socket.onConnectError((data) {
      print("❌ Connect Error to $address: $data");
      socket.dispose();

      // Try next address after a short delay
      Future.delayed(Duration(milliseconds: 1000), () {
        _tryConnectToAddress(addresses, index + 1);
      });
    });

    socket.onError((data) {
      print("❌ Socket Error on $address: $data");
      // Don't change connection state here, let onConnectError handle it
    });

    socket.onDisconnect((_) {
      print("🔌 Socket disconnected from $address");
      setState(() {
        isSocketConnected = false;
      });
    });

    socket.onReconnect((_) {
      print("🔄 Socket reconnected to $address");
      setState(() {
        isSocketConnected = true;
      });
      socket.emit("signin", widget.sourceChat?.id);
    });

    socket.connect();
    print("🔄 Connecting to socket at $address...");
  }

  void _reconnectSocket() {
    print("🔄 Manual reconnection triggered...");
    setState(() {
      isSocketConnected = false;
    });

    if (socket.connected) {
      socket.disconnect();
    }

    // Wait a moment then reconnect
    Future.delayed(Duration(milliseconds: 500), () {
      connect();
    });
  }

  void _connectAsEmulator() {
    print("🤖 Forcing emulator connection mode...");
    setState(() {
      isSocketConnected = false;
    });

    if (socket.connected) {
      socket.disconnect();
    }

    // Force emulator connection with priority order
    List<String> emulatorAddresses = [
      "http://10.0.2.2:8000",
      "http://127.0.0.1:8000",
      "http://localhost:8000",
    ];

    print("🌐 Forcing emulator addresses:");
    for (int i = 0; i < emulatorAddresses.length; i++) {
      print("   ${i + 1}. ${emulatorAddresses[i]}");
    }

    Future.delayed(Duration(milliseconds: 500), () {
      _tryConnectToAddress(emulatorAddresses, 0);
    });
  }

  Future<void> _testServerConnection() async {
    print("🧪 Testing server connection...");
    print("🔍 Source ID: ${widget.sourceChat?.id}");
    print("🔍 Target ID: ${widget.chatModel?.id}");

    try {
      // Detect device type
      bool isEmulator =
          Platform.isAndroid &&
          (Platform.environment['ANDROID_DATA']?.contains('emulator') == true ||
              Platform.environment['FLUTTER_TEST'] == 'true');

      print(
        "🤖 Testing from: ${isEmulator ? 'Android Emulator' : 'Physical Device'}",
      );

      final addresses = isEmulator
          ? [
              '10.0.2.2', // Primary for emulator
              '127.0.0.1',
              'localhost',
              '192.168.8.123',
              '192.168.56.1',
            ]
          : [
              '192.168.8.123', // Primary for physical device
              '192.168.56.1',
              '10.0.2.2',
              'localhost',
              '127.0.0.1',
            ];

      bool foundConnection = false;
      for (String address in addresses) {
        try {
          print("🔍 Testing TCP connection to $address:8000...");
          final socket = await Socket.connect(
            address,
            8000,
            timeout: Duration(seconds: 3),
          );
          print("✅ Successfully connected to $address:8000");
          socket.destroy();

          if (!foundConnection) {
            print("💡 Recommended server address: http://$address:8000");
            foundConnection = true;
          }
        } catch (e) {
          print("❌ Failed to connect to $address:8000: $e");
        }
      }

      if (!foundConnection) {
        print("❌ All server connection tests failed");
        print(
          "💡 Check: 1) Server running 2) Firewall allows port 8000 3) Network connectivity",
        );
      }
    } catch (e) {
      print("❌ Server connection test error: $e");
    }
  }

  void _checkServerUsers() {
    print("👥 Checking server user status...");
    print("🔍 My User ID: ${widget.sourceChat?.id}");
    print("🎯 Looking for Target ID: ${widget.chatModel?.id}");
    print("🔌 Socket Connected: ${socket.connected}");
    print("🆔 Socket ID: ${socket.id}");

    if (socket.connected) {
      print("💬 Requesting server user list...");
      socket.emit("requestUserList");
    } else {
      print("❌ Cannot check users - socket not connected");
    }
  }

  void sendMessage(
    String message,
    String sourceId,
    String targetId,
    String path,
  ) {
    print("📤 ========== SENDING MESSAGE ==========");
    print("   Message: '$message'");
    print("   SourceId: $sourceId");
    print("   TargetId: $targetId");
    print("   Path: $path");
    print("   Socket connected: ${socket.connected}");
    print("   Socket ID: ${socket.id}");

    if (sourceId == targetId) {
      print("⚠️  WARNING: Source and Target IDs are the same!");
      print("   This means you're trying to send a message to yourself.");
      print(
        "   Make sure you're using different user accounts on each device.",
      );
    }

    if (!socket.connected) {
      print("❌ Socket not connected, cannot send message");
      print("💡 Try using 'Reconnect' from the menu");
      return;
    }

    // Add message to UI immediately for instant feedback
    _addOutgoingMessage(message, path);

    final messageData = {
      "message": message,
      "sourceId": sourceId,
      "targetId": targetId,
      "messageType": path.isNotEmpty ? "image" : "text",
      "path": path,
    };

    print("📡 Emitting to server: $messageData");
    socket.emit("message", messageData);
    print("✅ Message emitted to server - waiting for server to route it");
    print("🔍 Server should look for user: $targetId");
    print("=========================================");
  }

  void _addOutgoingMessage(String message, String path) {
    final newMessage = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      chatId: widget.chatModel?.id ?? '',
      senderId: widget.sourceChat?.id ?? '',
      message: message,
      timestamp: DateTime.now(),
      isMe: true,
      messageType: path.isNotEmpty ? 'image' : 'text',
      path: path,
      time: _formatTime(DateTime.now().toIso8601String()),
    );

    setState(() {
      messages.add(newMessage);
      lastMessageId = newMessage.id;
    });

    // Auto-scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    print("✅ Added outgoing message to UI immediately");
  }

  void setMessage(String type, String message, String path) {
    MessageModel messageModel = MessageModel.legacy(
      type: type == "source" ? "source" : "destination",
      message: message,
      path: path,
      time: DateTime.now().toString().substring(10, 16),
    );

    // Set isMe based on type
    if (type == "source") {
      messageModel = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatModel?.id ?? '',
        senderId: widget.sourceChat?.id ?? '',
        message: message,
        timestamp: DateTime.now(),
        isMe: true,
        messageType: 'text',
        path: path,
        time: DateTime.now().toString().substring(10, 16),
      );
    } else {
      messageModel = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatModel?.id ?? '',
        senderId: widget.chatModel?.id ?? '',
        message: message,
        timestamp: DateTime.now(),
        isMe: false,
        messageType: 'text',
        path: path,
        time: DateTime.now().toString().substring(10, 16),
      );
    }

    setState(() {
      messages.add(messageModel);
    });
  }

  void onImageSend(String path, String message) async {
    print("working hey there $message");
    for (int i = 0; i < popTime; i++) {
      Navigator.pop(context); // Close the bottom sheet or camera view
    }
    setState(() {
      popTime = 0;
    });
    var request = http.MultipartRequest(
      "POST",
      Uri.parse("http://192.168.56.1/route/addimage"),
    );
    request.files.add(await http.MultipartFile.fromPath('image', path));
    request.headers.addAll({'Content-Type': 'multipart/form-data'});
    http.StreamedResponse response = await request.send();
    var httpResponse = await http.Response.fromStream(response);
    var data = json.decode(httpResponse.body);
    print(data['path']);
    print(response.statusCode);
    setMessage("source", message, path);
    socket.emit("message", {
      "message": message,
      "sourceId": widget.sourceChat?.id,
      "targetId": widget.chatModel?.id,
      "path": path,
    });
  }

  void _addIncomingMessage(Map<String, dynamic> messageData) {
    try {
      final newMessage = MessageModel(
        id:
            messageData['id']?.toString() ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        chatId: widget.chatModel?.id ?? '',
        senderId: messageData['sourceId'] ?? '',
        message: messageData['message'] ?? '',
        timestamp: DateTime.now(),
        isMe: false,
        messageType: messageData['messageType'] ?? 'text',
        path: messageData['path'] ?? '',
        time: _formatTime(DateTime.now().toIso8601String()),
      );

      setState(() {
        // Check if message already exists to avoid duplicates
        bool messageExists = messages.any((msg) => msg.id == newMessage.id);
        if (!messageExists) {
          messages.add(newMessage);
          lastMessageId = newMessage.id;
        }
      });

      // Auto-scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });

      print("✅ Added real-time message to UI");
    } catch (e) {
      print("❌ Error adding incoming message: $e");
    }
  }

  void _handleMessageSentConfirmation(Map<String, dynamic> data) {
    print("📬 Message sent confirmation: $data");
    // You can update message status here if needed
    // For example, mark message as delivered
  }

  void _handleMessageDelivered(Map<String, dynamic> data) {
    print("📬 Message delivered: $data");
    // Update the message status to delivered in the UI
    setState(() {
      // Find the message and update its status
      var message = messages.firstWhere(
        (msg) => msg.id == data['messageId'],
        orElse: () => MessageModel(
          id: '',
          message: '',
          senderId: '',
          chatId: '',
          timestamp: DateTime.now(),
          isMe: false,
          path: '',
        ),
      );
      if (message.id.isNotEmpty) {
        message.isDelivered = true;
      }
    });
  }

  void _handleMessagePending(Map<String, dynamic> data) {
    print("⏳ Message pending: $data");
    // Update the message status to pending in the UI
    setState(() {
      // Find the message and update its status
      var message = messages.firstWhere(
        (msg) => msg.id == data['messageId'],
        orElse: () => MessageModel(
          id: '',
          message: '',
          senderId: '',
          chatId: '',
          timestamp: DateTime.now(),
          isMe: false,
          path: '',
        ),
      );
      if (message.id.isNotEmpty) {
        message.isPending = true;
      }
    });
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      return "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Image.asset(
          'assets/whatsapp_back.jpg',
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          fit: BoxFit.cover,
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            titleSpacing: 0,
            backgroundColor: const Color(0xff075E54),
            leadingWidth: 100,
            leading: InkWell(
              onTap: () {
                Navigator.pop(context);
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_back, color: Colors.white),
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blueGrey,
                    child: SvgPicture.asset(
                      (widget.chatModel?.isGroup ?? false)
                          ? 'assets/groups.svg'
                          : 'assets/person.svg',
                      width: 38,
                      height: 38,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            title: InkWell(
              onTap: () {},
              child: Container(
                margin: EdgeInsets.all(5),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.chatModel?.name ?? 'Unknown',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      isSocketConnected ? 'Connected ✓' : 'Connecting...',
                      style: TextStyle(
                        fontSize: 13,
                        color: isSocketConnected
                            ? Color(0xff25D366)
                            : Colors.white.withOpacity(0.7),
                      ),
                    ),
                    Text(
                      'Source: ${widget.sourceChat?.id != null ? widget.sourceChat!.id.substring(0, 8) : 'Unknown'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                    Text(
                      'Target: ${widget.chatModel?.id != null ? widget.chatModel!.id.substring(0, 8) : 'Unknown'}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(icon: const Icon(Icons.video_call), onPressed: () {}),
              IconButton(icon: const Icon(Icons.call), onPressed: () {}),
              PopupMenuButton<String>(
                onSelected: (value) {
                  print(value);
                  if (value == "Reconnect") {
                    _reconnectSocket();
                  } else if (value == "Test Connection") {
                    _testServerConnection();
                  } else if (value == "Force Emulator Mode") {
                    _connectAsEmulator();
                  } else if (value == "Check Server Status") {
                    _checkServerUsers();
                  }
                },
                itemBuilder: (context) {
                  return [
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(
                            isSocketConnected ? Icons.wifi : Icons.wifi_off,
                            color: isSocketConnected
                                ? Colors.green
                                : Colors.red,
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text('Reconnect'),
                        ],
                      ),
                      value: "Reconnect",
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.network_check, size: 20),
                          SizedBox(width: 8),
                          Text('Test Connection'),
                        ],
                      ),
                      value: "Test Connection",
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.android, color: Colors.green, size: 20),
                          SizedBox(width: 8),
                          Text('Force Emulator Mode'),
                        ],
                      ),
                      value: "Force Emulator Mode",
                    ),
                    PopupMenuItem(
                      child: Row(
                        children: [
                          Icon(Icons.people, color: Colors.blue, size: 20),
                          SizedBox(width: 8),
                          Text('Check Server Status'),
                        ],
                      ),
                      value: "Check Server Status",
                    ),
                    PopupMenuItem(
                      child: Text('View Contact'),
                      value: "View Contact",
                    ),
                    PopupMenuItem(
                      child: Text('links, media, and docs'),
                      value: "links, media, and docs",
                    ),
                    PopupMenuItem(child: Text('Search'), value: "Search"),
                    PopupMenuItem(
                      child: Text('Mute Notifications'),
                      value: "Mute Notifications",
                    ),
                    PopupMenuItem(child: Text('Wallpaper'), value: "Wallpaper"),
                  ];
                },
              ),
            ],
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: WillPopScope(
              child: Column(
                children: [
                  Expanded(
                    // height: MediaQuery.of(context).size.height - 144,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        if (messages[index].isMe) {
                          if (messages[index].path.length > 0) {
                            return OwnFileCard(
                              path: messages[index].path,
                              message: messages[index].message,
                              time: messages[index].time ?? '',
                            );
                          } else {
                            return OwnMessageCard(message: messages[index]);
                          }
                        } else {
                          if (messages[index].path.length > 0) {
                            return ReplyFileCard(
                              path: messages[index].path,
                              message: messages[index].message,
                              time: messages[index].time ?? '',
                            );
                          } else {
                            return ReplyMessageCard(
                              message: messages[index].message,
                              time: messages[index].time,
                            );
                          }
                        }
                      },
                    ),
                    // child: ListView(children: [OwnFileCard(), ReplyFileCard()]),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: MediaQuery.of(context).size.width - 55,
                              child: Card(
                                margin: EdgeInsets.only(
                                  left: 2,
                                  right: 2,
                                  bottom: 8,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: TextFormField(
                                  controller: textFieldController,
                                  focusNode: textFieldFocusNode,
                                  textAlignVertical: TextAlignVertical.center,
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                  keyboardType: TextInputType.multiline,
                                  maxLines: 5,
                                  minLines: 1,
                                  //after typing the message, the send button will appear
                                  onChanged: (value) {
                                    if (value.length > 0) {
                                      setState(() {
                                        sendButton = true;
                                      });
                                    } else {
                                      setState(() {
                                        sendButton = false;
                                      });
                                    }
                                  },
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    hintText: 'Type a message',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 10,
                                    ),
                                    prefixIcon: IconButton(
                                      onPressed: () {
                                        setState(() {
                                          textFieldFocusNode.unfocus();
                                          textFieldFocusNode.canRequestFocus =
                                              false;
                                          isEmojiVisible = !isEmojiVisible;
                                        });
                                      },
                                      icon: Icon(
                                        Icons.emoji_emotions,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                    suffixIcon: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.attach_file,
                                            color: Colors.blueGrey,
                                          ),
                                          onPressed: () {
                                            showModalBottomSheet(
                                              backgroundColor:
                                                  Colors.transparent,
                                              context: context,
                                              builder: (builder) =>
                                                  bottomSheet(),
                                            );
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.camera_alt,
                                            color: Colors.blueGrey,
                                          ),
                                          onPressed: () async {
                                            setState(() {
                                              popTime = 3;
                                            });
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (builder) =>
                                                    CameraScreen(
                                                      onImageSend: onImageSend,
                                                    ),
                                              ),
                                            );
                                          },
                                          // Use the new method here too
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            CircleAvatar(
                              radius: 25,
                              backgroundColor: const Color(0xff128C7E),
                              child: IconButton(
                                icon: Icon(
                                  sendButton ? Icons.send : Icons.mic,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  // Handle send action
                                  if (sendButton &&
                                      widget.sourceChat?.id != null &&
                                      widget.chatModel?.id != null &&
                                      textFieldController.text
                                          .trim()
                                          .isNotEmpty) {
                                    sendMessage(
                                      textFieldController.text.trim(),
                                      widget.sourceChat!.id,
                                      widget.chatModel!.id,
                                      '', // Pass an empty string for path if not sending a file
                                    );
                                    // Clear the text field after sending
                                    textFieldController.clear();
                                    setState(() {
                                      sendButton = false;
                                    });
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        isEmojiVisible
                            ? emojiPicker()
                            : Container(), // Emoji picker widget
                      ],
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                if (isEmojiVisible) {
                  setState(() {
                    isEmojiVisible = false;
                  });
                } else {
                  Navigator.pop(context);
                }
                return Future.value(false);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget bottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Card(
        margin: EdgeInsets.all(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10),
                  increation(
                    icon: Icons.insert_drive_file,
                    color: Colors.indigo,
                    text: 'Document',
                    onTap: () {},
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.camera_alt,
                    color: Colors.red,
                    text: 'Camera',
                    onTap: () async {
                      setState(() {
                        popTime = 2;
                      });
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (builder) => CameraScreen(
                            onImageSend: onImageSend, // Pass the new method
                          ),
                        ),
                      );
                    }, // Use the new method
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.photo_library,
                    color: Colors.purple,
                    text: 'Gallery',
                    onTap: () async {
                      setState(() {
                        popTime = 2;
                      });
                      file = await _picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (file != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (Builder) => CameraView(
                              path: file!.path,
                              onImageSend: onImageSend, // Pass the new method),
                            ),
                          ),
                        );
                      }
                    }, // Use the new method
                  ),
                ],
              ),
              SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(width: 10),
                  increation(
                    icon: Icons.headset,
                    color: Colors.orange,
                    text: 'Audio',
                    onTap: () {},
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.location_on,
                    color: Colors.pinkAccent,
                    text: 'Location',
                    onTap: () {},
                  ),
                  SizedBox(width: 40),
                  increation(
                    icon: Icons.person,
                    color: Colors.blue,
                    text: 'Contact',
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget increation({
    required icon,
    required Color color,
    required String text,
    GestureTapCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icon, size: 29, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(text),
        ],
      ),
    );
  }

  Widget emojiPicker() {
    return SizedBox(
      height: 250,
      width: MediaQuery.of(context).size.width,
      child: EmojiPicker(
        onEmojiSelected: (category, emoji) {
          print(emoji);
          setState(() {
            textFieldController.text += emoji.emoji;
          });
        },
      ),
    );
  }
}
