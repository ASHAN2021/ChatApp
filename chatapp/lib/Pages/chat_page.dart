import 'dart:convert';
import 'dart:async';
import 'package:chatapp/Model/chat_model.dart';
import 'package:chatapp/Model/user_model.dart';
import 'package:chatapp/Screens/individual_page.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ChatPage extends StatefulWidget {
  const ChatPage({super.key, this.chats, this.sourceChat, this.currentUser});
  final List<ChatModel>? chats;
  final ChatModel? sourceChat;
  final UserModel? currentUser;

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  List<UserModel> availableUsers = [];
  List<dynamic> conversations = [];
  bool isLoading = true;
  String? error;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    if (widget.currentUser != null) {
      loadAvailableUsers();
      loadConversations();
      _startPeriodicRefresh(); // Add periodic refresh
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _startPeriodicRefresh() {
    // Refresh conversations every 3 seconds to catch new messages
    _refreshTimer = Timer.periodic(Duration(seconds: 3), (timer) {
      if (mounted) {
        loadConversations();
      }
    });
  }

  Future<void> loadAvailableUsers() async {
    try {
      final response = await http
          .get(
            Uri.parse("http://10.0.2.2:8000/api/users"),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> userData = json.decode(response.body);
        setState(() {
          availableUsers = userData
              .map((user) => UserModel.fromJson(user))
              .where((user) => user.id != widget.currentUser?.id)
              .toList();
        });
      }
    } catch (e) {
      print("❌ Error loading users: $e");
    }
  }

  Future<void> loadConversations() async {
    if (widget.currentUser == null) return;

    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final response = await http
          .get(
            Uri.parse(
              "http://10.0.2.2:8000/api/conversations/${widget.currentUser!.id}",
            ),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> conversationData = json.decode(response.body);
        setState(() {
          conversations = conversationData;
          isLoading = false;
        });
      } else {
        setState(() {
          error = "Failed to load conversations";
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print("❌ Error loading conversations: $e");
    }
  }

  void startChatWithUser(UserModel user) {
    // Convert UserModel to ChatModel for compatibility with existing screens
    final chatModel = ChatModel(
      id: user.id,
      name: user.name,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      profileImage: user.profileImage,
      isOnline: user.isOnline,
      unreadCount: 0,
    );

    final sourceChat = ChatModel(
      id: widget.currentUser!.id,
      name: widget.currentUser!.name,
      lastMessage: '',
      lastMessageTime: DateTime.now(),
      profileImage: widget.currentUser!.profileImage,
      isOnline: true,
      unreadCount: 0,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            IndividualPage(chatModel: chatModel, sourceChat: sourceChat),
      ),
    ).then((_) {
      // Refresh conversations when returning from chat
      loadConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUser == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No user selected',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            Text(
              'Please select a user to continue',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showUserSelectionDialog();
        },
        backgroundColor: const Color(0xff128C7E),
        child: const Icon(Icons.chat, color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await loadConversations();
          await loadAvailableUsers();
        },
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
                    Text(
                      'Loading conversations...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              )
            : error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red),
                    SizedBox(height: 16),
                    Text(
                      'Error: $error',
                      style: TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: loadConversations,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : conversations.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'No conversations yet',
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Tap the + button to start a new chat',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : RefreshIndicator(
                onRefresh: loadConversations,
                child: ListView.builder(
                  itemCount: conversations.length,
                  itemBuilder: (context, index) {
                    final conversation = conversations[index];
                    return ConversationCard(
                      conversation: conversation,
                      currentUser: widget.currentUser!,
                      onTap: () {
                      final otherUser = UserModel(
                        id: conversation['otherUserId'],
                        name: conversation['otherUserName'],
                        profileImage:
                            conversation['otherUserProfileImage'] ?? '',
                        qrCode: '',
                        createdAt: DateTime.now(),
                        mobile: conversation['otherUserMobile'] ?? '',
                        isOnline: (conversation['otherUserIsOnline'] ?? 0) == 1,
                      );
                      startChatWithUser(otherUser);
                    },
                  );
                },
              ),
            ), // Close RefreshIndicator
      ),
    );
  }

  void _showUserSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start New Chat'),
          content: Container(
            width: double.maxFinite,
            child: availableUsers.isEmpty
                ? Container(
                    height: 100,
                    child: Center(child: Text('No users available')),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableUsers.length,
                    itemBuilder: (context, index) {
                      final user = availableUsers[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Color(0xff075E54),
                          backgroundImage: user.profileImage.isNotEmpty
                              ? NetworkImage(user.profileImage)
                              : null,
                          child: user.profileImage.isEmpty
                              ? Text(
                                  user.name
                                      .split(' ')
                                      .map((e) => e[0])
                                      .take(2)
                                      .join(),
                                  style: TextStyle(color: Colors.white),
                                )
                              : null,
                        ),
                        title: Text(user.name),
                        subtitle: Text(user.mobile),
                        trailing: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: user.isOnline ? Colors.green : Colors.grey,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context);
                          startChatWithUser(user);
                        },
                      );
                    },
                  ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}

class ConversationCard extends StatelessWidget {
  final Map<String, dynamic> conversation;
  final UserModel currentUser;
  final VoidCallback onTap;

  const ConversationCard({
    Key? key,
    required this.conversation,
    required this.currentUser,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final unreadCount = conversation['unreadCount'] ?? 0;
    final isOnline = (conversation['otherUserIsOnline'] ?? 0) == 1;
    final lastMessageTime = conversation['lastMessageTime'];
    final profileImage = conversation['otherUserProfileImage'] ?? '';

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: Stack(
          children: [
            CircleAvatar(
              backgroundColor: Color(0xff075E54),
              backgroundImage: profileImage.isNotEmpty
                  ? NetworkImage(profileImage)
                  : null,
              child: profileImage.isEmpty
                  ? Text(
                      conversation['otherUserName']
                          .toString()
                          .split(' ')
                          .map((e) => e[0])
                          .take(2)
                          .join(),
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            if (isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
          ],
        ),
        title: Text(
          conversation['otherUserName'] ?? 'Unknown',
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation['lastMessage'] ?? 'No messages yet',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: unreadCount > 0 ? FontWeight.w500 : FontWeight.normal,
            color: unreadCount > 0 ? Colors.black87 : Colors.grey[600],
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (lastMessageTime != null)
              Text(
                _formatTime(lastMessageTime),
                style: TextStyle(
                  fontSize: 12,
                  color: unreadCount > 0 ? Color(0xff075E54) : Colors.grey,
                  fontWeight: unreadCount > 0
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            if (unreadCount > 0)
              Container(
                margin: EdgeInsets.only(top: 4),
                padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xff25D366),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  unreadCount.toString(),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final DateTime now = DateTime.now();
      final Duration difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return '';
    }
  }
}
