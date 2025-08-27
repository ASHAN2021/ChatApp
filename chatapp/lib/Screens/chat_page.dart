import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../Model/chat_model.dart';
import '../Model/message_model.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';
import '../CustomUI/own_message_card.dart';
import '../CustomUI/reply_card.dart';

class ChatPage extends StatefulWidget {
  final ChatModel chat;

  const ChatPage({Key? key, required this.chat}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = Uuid();

  List<MessageModel> messages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _markMessagesAsRead();
  }

  Future<void> _loadMessages() async {
    try {
      final loadedMessages = await _databaseService.getMessagesForChat(
        widget.chat.id,
      );
      setState(() {
        messages = loadedMessages;
        isLoading = false;
      });
      _scrollToBottom();
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      NotificationService.showError(context, 'Failed to load messages');
    }
  }

  Future<void> _markMessagesAsRead() async {
    await _databaseService.markMessagesAsRead(widget.chat.id);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty) return;

    final message = MessageModel(
      id: _uuid.v4(),
      chatId: widget.chat.id,
      senderId:
          'current_user', // In a real app, this would be the current user's ID
      message: messageText,
      timestamp: DateTime.now(),
      isMe: true,
      path: '',
    );

    // Clear the input field immediately
    _messageController.clear();

    // Add message to local list
    setState(() {
      messages.add(message);
    });

    // Save to database
    try {
      await _databaseService.insertMessage(message);
      _scrollToBottom();
    } catch (e) {
      NotificationService.showError(context, 'Failed to send message');
      // Remove message from local list if failed to save
      setState(() {
        messages.removeLast();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Color(0xff075E54),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back, color: Colors.white),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white,
              child: widget.chat.profileImage.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.chat.profileImage,
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.person,
                            color: Color(0xff075E54),
                            size: 25,
                          );
                        },
                      ),
                    )
                  : Icon(Icons.person, color: Color(0xff075E54), size: 25),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.chat.name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.chat.isOnline ? 'Online' : 'Offline',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onSelected: (value) {
              switch (value) {
                case 'clear':
                  _showClearChatDialog();
                  break;
                case 'delete':
                  _showDeleteChatDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.clear_all, color: Colors.grey[700]),
                      SizedBox(width: 10),
                      Text('Clear Messages'),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete Chat'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/whatsapp_back.jpg'),
            fit: BoxFit.cover,
            opacity: 0.1,
          ),
        ),
        child: Column(
          children: [
            // Messages list
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : messages.isEmpty
                  ? _buildEmptyMessageState()
                  : ListView.builder(
                      controller: _scrollController,
                      padding: EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        return message.isMe
                            ? OwnMessageCard(message: message)
                            : ReplyCard(message: message);
                      },
                    ),
            ),

            // Message input
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 5,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 10,
                          ),
                          suffixIcon: IconButton(
                            onPressed: () {
                              // TODO: Add emoji picker
                            },
                            icon: Icon(Icons.emoji_emotions_outlined),
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Color(0xff075E54),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: Icon(Icons.send, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyMessageState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 60,
                    color: Color(0xff075E54),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Start Conversation',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff075E54),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Send your first message to ${widget.chat.name}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear Messages'),
          content: Text(
            'Are you sure you want to clear all messages in this chat?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                // Clear messages from database
                // TODO: Implement clear messages functionality
                setState(() {
                  messages.clear();
                });
                NotificationService.showSuccess(context, 'Messages cleared');
              },
              child: Text('Clear'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteChatDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Chat'),
          content: Text(
            'Are you sure you want to delete this chat? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.deleteChat(widget.chat.id);
                Navigator.of(context).pop(); // Go back to chat list
                NotificationService.showSuccess(context, 'Chat deleted');
              },
              child: Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
