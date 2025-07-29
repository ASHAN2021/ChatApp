import 'dart:convert';
import 'dart:io';
import 'package:chatapp/CustomUI/own_file_card.dart';
import 'package:chatapp/CustomUI/own_message_card.dart';
import 'package:chatapp/CustomUI/reply_file_card.dart';
import 'package:chatapp/CustomUI/reply_message.dart';
import 'package:chatapp/Model/chat_model.dart';
import 'package:chatapp/Model/message_model.dart';
import 'package:chatapp/Screens/camera_screen.dart';
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
  bool isLoading = true;
  String? error;
  bool isTyping = false;
  bool otherUserTyping = false;
  String serverUrl = "";

  @override
  void initState() {
    super.initState();
    loadMessageHistory();
    connect();
    textFieldFocusNode.addListener(() {
      if (textFieldFocusNode.hasFocus) {
        setState(() {
          isEmojiVisible = false;
        });
      }
    });

    textFieldController.addListener(() {
      final isCurrentlyTyping = textFieldController.text.isNotEmpty;
      if (isCurrentlyTyping != isTyping) {
        setState(() {
          isTyping = isCurrentlyTyping;
        });
        if (isSocketConnected) {
          socket.emit("typing", {
            "targetId": widget.chatModel?.id,
            "isTyping": isCurrentlyTyping,
          });
        }
      }
    });
  }

  Future<void> loadMessageHistory() async {
    if (widget.sourceChat?.id == null || widget.chatModel?.id == null) {
      setState(() {
        isLoading = false;
        error = "Invalid user data";
      });
      return;
    }

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Try multiple server addresses
      List<String> serverAddresses = [
        "http://10.0.2.2:8000", // Android emulator
        "http://localhost:8000", // iOS simulator
        "http://127.0.0.1:8000", // Localhost
        "http://192.168.8.123:8000", // WiFi IP
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
            serverUrl = url;
            print("✅ Successfully loaded messages from: $url");
            break;
          }
        } catch (e) {
          print("❌ Failed to load messages from $url: $e");
          continue;
        }
      }

      if (response == null || response.statusCode != 200) {
        throw Exception('Unable to load message history from server');
      }

      final List<dynamic> messageData = json.decode(response.body);
      List<MessageModel> loadedMessages = [];

      for (var msg in messageData) {
        loadedMessages.add(
          MessageModel(
            id: msg['id']?.toString() ?? '',
            chatId: msg['chatId'] ?? '',
            senderId: msg['senderId'] ?? '',
            message: msg['message'] ?? '',
            timestamp: DateTime.fromMillisecondsSinceEpoch(
              msg['timestamp'] ?? 0,
            ),
            isMe: msg['sourceId'] == widget.sourceChat?.id,
            messageType: msg['messageType'] ?? 'text',
            path: msg['path'] ?? '',
            isRead: (msg['isRead'] ?? 0) == 1,
            time: _formatTime(msg['timestamp']),
          ),
        );
      }

      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });

      print("📨 Loaded ${messages.length} messages");

      // Mark messages as read
      await _markMessagesAsRead();
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print("❌ Error loading message history: $e");
    }
  }

  Future<void> _markMessagesAsRead() async {
    if (serverUrl.isEmpty) return;

    try {
      await http.post(
        Uri.parse("$serverUrl/api/messages/markread"),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': widget.sourceChat?.id,
          'otherUserId': widget.chatModel?.id,
        }),
      );
    } catch (e) {
      print("❌ Error marking messages as read: $e");
    }
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

  void connect() {
    print("🔄 Initializing socket connection...");
    _connectWithFallback();
  }

  void _connectWithFallback() {
    print("🔍 Detecting device type for optimal connection...");
    print("🔍 Source Chat ID: ${widget.sourceChat?.id}");
    print("🔍 Target Chat ID: ${widget.chatModel?.id}");

    bool isEmulator =
        Platform.isAndroid &&
        (Platform.environment['ANDROID_DATA']?.contains('emulator') == true ||
            Platform.environment['FLUTTER_TEST'] == 'true');

    print(
      "🤖 Device type detected: ${isEmulator ? 'Android Emulator' : 'Physical Device'}",
    );

    List<String> serverAddresses;
    if (isEmulator) {
      serverAddresses = [
        "http://10.0.2.2:8000",
        "http://127.0.0.1:8000",
        "http://localhost:8000",
        "http://192.168.8.123:8000",
      ];
    } else {
      serverAddresses = [
        "http://192.168.8.123:8000",
        "http://10.0.2.2:8000",
        "http://localhost:8000",
        "http://127.0.0.1:8000",
      ];
    }

    print("🌐 Will try addresses in this order:");
    for (int i = 0; i < serverAddresses.length; i++) {
      print("   ${i + 1}. ${serverAddresses[i]}");
    }

    _tryConnectToAddress(serverAddresses, 0);
  }

  void _tryConnectToAddress(List<String> addresses, int index) {
    if (index >= addresses.length) {
      print("❌ All connection attempts failed!");
      _showConnectionError();
      return;
    }

    final address = addresses[index];
    print(
      "🔄 Attempting connection to: $address (${index + 1}/${addresses.length})",
    );

    socket = IO.io(address, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'timeout': 10000,
      'reconnection': true,
      'reconnectionAttempts': 3,
      'reconnectionDelay': 2000,
    });

    socket.onConnect((_) {
      print("✅ Socket connected successfully to: $address");
      setState(() {
        isSocketConnected = true;
        serverUrl = address;
      });

      // Sign in the user
      socket.emit("signin", widget.sourceChat?.id);
      print("👤 Signed in user: ${widget.sourceChat?.id}");
    });

    socket.on("message", (data) {
      print("📨 Message received: $data");
      try {
        if (data != null && data['message'] != null) {
          _addMessage("destination", data['message'], data['path'] ?? '');
        }
      } catch (e) {
        print("❌ Error processing message: $e");
      }
    });

    socket.on("messageSent", (data) {
      print("✅ Message sent confirmation: $data");
      // Message already added to UI when sending, just update if needed
    });

    socket.on("typing", (data) {
      if (data['userId'] == widget.chatModel?.id) {
        setState(() {
          otherUserTyping = data['isTyping'] ?? false;
        });
      }
    });

    socket.on("userOnline", (userId) {
      if (userId == widget.chatModel?.id) {
        setState(() {
          widget.chatModel?.isOnline = true;
        });
      }
    });

    socket.on("userOffline", (userId) {
      if (userId == widget.chatModel?.id) {
        setState(() {
          widget.chatModel?.isOnline = false;
        });
      }
    });

    socket.onConnectError((data) {
      print("❌ Connect Error to $address: $data");
      socket.dispose();
      Future.delayed(Duration(milliseconds: 1000), () {
        _tryConnectToAddress(addresses, index + 1);
      });
    });

    socket.onDisconnect((_) {
      print("🔌 Socket disconnected from $address");
      setState(() {
        isSocketConnected = false;
      });
    });

    socket.connect();
    print("🔄 Connecting to socket at $address...");
  }

  void _showConnectionError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Connection Error'),
          content: Text(
            'Unable to connect to the chat server. Please check if the server is running and try again.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _connectWithFallback();
              },
              child: Text('Retry'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: Text('Go Back'),
            ),
          ],
        );
      },
    );
  }

  void sendMessage(String message, String messageType, {String? path}) {
    if (!isSocketConnected) {
      _showSnackBar("Not connected to server", Colors.red);
      return;
    }

    if (message.trim().isEmpty && messageType == 'text') return;

    // Add message to UI immediately
    _addMessage("source", message, path ?? '');

    // Send to server
    socket.emit("message", {
      "message": message,
      "sourceId": widget.sourceChat?.id,
      "targetId": widget.chatModel?.id,
      "messageType": messageType,
      "path": path ?? "",
    });

    print("📤 Message sent: $message");
  }

  void _addMessage(String type, String message, String path) {
    setState(() {
      messages.add(
        MessageModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          message: message,
          type: type,
          time: _formatTime(DateTime.now().toIso8601String()),
          messageType: path.isNotEmpty ? 'image' : 'text',
          path: path,
          isRead: type == "source",
        ),
      );
    });

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    // Implement scroll to bottom if using ScrollController
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    socket.dispose();
    textFieldController.dispose();
    textFieldFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: MediaQuery.of(context).size.height,
          width: MediaQuery.of(context).size.width,
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage("assets/whatsapp_back.jpg"),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: AppBar(
              leadingWidth: 70,
              titleSpacing: 0,
              leading: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.arrow_back, size: 24, color: Colors.white),
                    CircleAvatar(
                      child: SvgPicture.asset(
                        widget.chatModel?.isGroup == true
                            ? "assets/groups.svg"
                            : "assets/person.svg",
                        color: Colors.white,
                        height: 36,
                        width: 36,
                      ),
                      radius: 20,
                      backgroundColor: Color(0xFF25D366),
                    ),
                  ],
                ),
              ),
              title: InkWell(
                onTap: () {},
                child: Container(
                  margin: EdgeInsets.all(6),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.chatModel?.name ?? "Unknown",
                        style: TextStyle(
                          fontSize: 18.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        isSocketConnected
                            ? otherUserTyping
                                  ? "typing..."
                                  : (widget.chatModel?.isOnline == true
                                        ? "online"
                                        : "offline")
                            : "connecting...",
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.videocam, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.call, color: Colors.white),
                  onPressed: () {},
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    print(value);
                  },
                  itemBuilder: (BuildContext context) {
                    return [
                      PopupMenuItem(
                        child: Text("View contact"),
                        value: "View contact",
                      ),
                      PopupMenuItem(
                        child: Text("Media, links, and docs"),
                        value: "Media, links, and docs",
                      ),
                      PopupMenuItem(child: Text("Search"), value: "Search"),
                      PopupMenuItem(
                        child: Text("Mute notifications"),
                        value: "Mute notifications",
                      ),
                      PopupMenuItem(
                        child: Text("Wallpaper"),
                        value: "Wallpaper",
                      ),
                    ];
                  },
                ),
              ],
              backgroundColor: Color(0xff075E54),
            ),
          ),
          body: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: WillPopScope(
              child: Column(
                children: [
                  Expanded(
                    child: isLoading
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xff075E54),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text("Loading messages..."),
                              ],
                            ),
                          )
                        : error != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Error: $error",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.red),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: loadMessageHistory,
                                  child: Text("Retry"),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: messages.length,
                            itemBuilder: (context, index) {
                              return messages[index].messageType == "text"
                                  ? messages[index].type == "source"
                                        ? OwnMessageCard(
                                            message: messages[index].message,
                                            time: messages[index].time,
                                          )
                                        : ReplyCard(
                                            message: messages[index].message,
                                            time: messages[index].time,
                                          )
                                  : messages[index].type == "source"
                                  ? OwnFileCard(
                                      path: messages[index].path,
                                      message: messages[index].message,
                                      time: messages[index].time,
                                    )
                                  : ReplyFileCard(
                                      path: messages[index].path,
                                      message: messages[index].message,
                                      time: messages[index].time,
                                    );
                            },
                          ),
                  ),
                  Container(
                    alignment: Alignment.bottomCenter,
                    width: MediaQuery.of(context).size.width,
                    child: Container(
                      height: 70,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: MediaQuery.of(context).size.width - 60,
                                child: Card(
                                  margin: EdgeInsets.only(
                                    left: 2,
                                    right: 2,
                                    bottom: 8,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(25),
                                  ),
                                  child: TextFormField(
                                    controller: textFieldController,
                                    focusNode: textFieldFocusNode,
                                    textAlignVertical: TextAlignVertical.center,
                                    keyboardType: TextInputType.multiline,
                                    maxLines: 5,
                                    minLines: 1,
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
                                      hintText: "Type a message",
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: IconButton(
                                        icon: Icon(
                                          isEmojiVisible
                                              ? Icons.keyboard
                                              : Icons.emoji_emotions_outlined,
                                        ),
                                        onPressed: () {
                                          if (!isEmojiVisible) {
                                            textFieldFocusNode.unfocus();
                                            textFieldFocusNode.canRequestFocus =
                                                false;
                                          }
                                          setState(() {
                                            isEmojiVisible = !isEmojiVisible;
                                          });
                                        },
                                      ),
                                      suffixIcon: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: Icon(Icons.attach_file),
                                            onPressed: () {
                                              showModalBottomSheet(
                                                backgroundColor:
                                                    Colors.transparent,
                                                context: context,
                                                builder: (builder) =>
                                                    _bottomSheet(),
                                              );
                                            },
                                          ),
                                          IconButton(
                                            icon: Icon(Icons.camera_alt),
                                            onPressed: () {
                                              _openCamera();
                                            },
                                          ),
                                        ],
                                      ),
                                      contentPadding: EdgeInsets.all(5),
                                    ),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 8,
                                  right: 2,
                                  left: 2,
                                ),
                                child: CircleAvatar(
                                  radius: 25,
                                  backgroundColor: Color(0xff128C7E),
                                  child: IconButton(
                                    icon: Icon(
                                      sendButton ? Icons.send : Icons.mic,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      if (sendButton) {
                                        sendMessage(
                                          textFieldController.text,
                                          "text",
                                        );
                                        setState(() {
                                          textFieldController.clear();
                                          sendButton = false;
                                        });
                                      }
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          isEmojiVisible ? _buildEmojiPicker() : Container(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              onWillPop: () {
                if (isEmojiVisible) {
                  setState(() {
                    isEmojiVisible = false;
                  });
                  return Future.value(false);
                } else {
                  return Future.value(true);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmojiPicker() {
    return EmojiPicker(
      onEmojiSelected: (category, emoji) {
        textFieldController.text = textFieldController.text + emoji.emoji;
        if (textFieldController.text.isNotEmpty) {
          setState(() {
            sendButton = true;
          });
        }
      },
      config: Config(
        columns: 7,
        emojiSizeMax: 32 * (Platform.isIOS ? 1.30 : 1.0),
        verticalSpacing: 0,
        horizontalSpacing: 0,
        initCategory: Category.RECENT,
        bgColor: const Color(0xFFF2F2F2),
        indicatorColor: Colors.blue,
        iconColor: Colors.grey,
        iconColorSelected: Colors.blue,
        recentsLimit: 28,
      ),
    );
  }

  Widget _bottomSheet() {
    return Container(
      height: 278,
      width: MediaQuery.of(context).size.width,
      child: Card(
        margin: const EdgeInsets.all(18.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconCreation(
                    Icons.insert_drive_file,
                    Colors.indigo,
                    "Document",
                  ),
                  SizedBox(width: 40),
                  _iconCreation(Icons.camera_alt, Colors.pink, "Camera"),
                  SizedBox(width: 40),
                  _iconCreation(Icons.insert_photo, Colors.purple, "Gallery"),
                ],
              ),
              SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _iconCreation(Icons.headset, Colors.orange, "Audio"),
                  SizedBox(width: 40),
                  _iconCreation(Icons.location_pin, Colors.teal, "Location"),
                  SizedBox(width: 40),
                  _iconCreation(Icons.person, Colors.blue, "Contact"),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _iconCreation(IconData icons, Color color, String text) {
    return InkWell(
      onTap: () {
        Navigator.pop(context);
        if (text == "Camera") {
          _openCamera();
        } else if (text == "Gallery") {
          _openGallery();
        }
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: color,
            child: Icon(icons, size: 29, color: Colors.white),
          ),
          SizedBox(height: 5),
          Text(text, style: TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  void _openCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
      );
      if (pickedFile != null) {
        setState(() {
          file = pickedFile;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraViewPage(
              path: file!.path,
              onImageSend: (String imagePath, String message) {
                sendMessage(message, "image", path: imagePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print("Error opening camera: $e");
    }
  }

  void _openGallery() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile != null) {
        setState(() {
          file = pickedFile;
        });
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CameraViewPage(
              path: file!.path,
              onImageSend: (String imagePath, String message) {
                sendMessage(message, "image", path: imagePath);
              },
            ),
          ),
        );
      }
    } catch (e) {
      print("Error opening gallery: $e");
    }
  }
}
