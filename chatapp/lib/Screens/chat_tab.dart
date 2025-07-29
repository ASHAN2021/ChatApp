import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../Model/chat_model.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';
import '../Services/sample_data.dart';
import 'individual_page.dart';

class ChatTab extends StatefulWidget {
  final VoidCallback? onNavigateToScan;

  const ChatTab({Key? key, this.onNavigateToScan}) : super(key: key);

  @override
  _ChatTabState createState() => _ChatTabState();
}

class _ChatTabState extends State<ChatTab> {
  final DatabaseService _databaseService = DatabaseService();
  List<ChatModel> chats = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadChats();
  }

  Future<void> _loadChats() async {
    try {
      final loadedChats = await _databaseService.getAllChats();

      // If no chats exist, add some sample chats for testing
      if (loadedChats.isEmpty) {
        final sampleChats = SampleData.getSampleChats();
        for (final chat in sampleChats) {
          await _databaseService.insertOrUpdateChat(chat);
        }
        // Reload chats after adding samples
        final updatedChats = await _databaseService.getAllChats();
        setState(() {
          chats = updatedChats;
          isLoading = false;
        });
      } else {
        setState(() {
          chats = loadedChats;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading chats: $e');

      // If it's a database schema error, offer to reset the database
      if (e.toString().contains('duplicate column name: isGroup') ||
          e.toString().contains('no column named isGroup')) {
        print('Database schema error detected, resetting database...');
        await _resetDatabaseAndReload();
      } else {
        setState(() {
          isLoading = false;
        });
        NotificationService.showError(context, 'Failed to load chats');
      }
    }
  }

  Future<void> _resetDatabaseAndReload() async {
    try {
      // Use the new force complete reset method
      await DatabaseService.forceCompleteReset();
      print('Force complete database reset completed, reloading chats...');
      await _loadChats();
      NotificationService.showSuccess(context, 'Database reset successfully!');
    } catch (e) {
      print('Error resetting database: $e');
      setState(() {
        isLoading = false;
      });
      NotificationService.showError(context, 'Failed to reset database');
    }
  }

  Future<void> _refreshChats() async {
    await _loadChats();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshChats,
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : chats.isEmpty
            ? _buildEmptyState()
            : ListView.builder(
                itemCount: chats.length,
                itemBuilder: (context, index) {
                  return _buildChatTile(chats[index]);
                },
              ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Debug reset button (can be removed in production)
          FloatingActionButton(
            onPressed: () async {
              final shouldReset = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Reset Database'),
                  content: Text(
                    'This will delete all chats and reset the database. Continue?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Reset', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );

              if (shouldReset == true) {
                await _resetDatabaseAndReload();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Database reset successfully!'),
                    backgroundColor: Color(0xff075E54),
                  ),
                );
              }
            },
            backgroundColor: Colors.orange,
            child: Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Reset Database',
            heroTag: "resetDB",
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: _showChatOptions,
            backgroundColor: Color(0xff075E54),
            child: Icon(Icons.chat, color: Colors.white),
            tooltip: 'Start New Chat',
            heroTag: "newChat",
          ),
          SizedBox(height: 10),
          FloatingActionButton(
            onPressed: () async {
              print('=== TEST CHAT BUTTON PRESSED ===');
              try {
                await _addTestChat();
                print('=== TEST CHAT BUTTON COMPLETED ===');
              } catch (e) {
                print('=== TEST CHAT BUTTON ERROR: $e ===');
              }
            },
            backgroundColor: Color(0xff128C7E),
            child: Icon(Icons.person_add, color: Colors.white),
            tooltip: 'Add Test Contact',
            heroTag: "testChat",
          ),
        ],
      ),
    );
  }

  Future<void> _addTestChat() async {
    try {
      print('Adding test chat...');
      final testChat = ChatModel(
        id: 'test_chat_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Test Contact ${chats.length + 1}',
        lastMessage: 'Ready to chat!',
        lastMessageTime: DateTime.now(),
        isOnline: true,
        isGroup: false, // Explicitly set isGroup to false
      );

      print('Test chat model created: ${testChat.toMap()}');
      await _databaseService.insertOrUpdateChat(testChat);
      print('Test chat inserted to database');

      await _refreshChats();
      print('Chats refreshed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Test chat added successfully!'),
          backgroundColor: Color(0xff075E54),
        ),
      );
    } catch (e) {
      print('Error adding test chat: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add test chat: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showChatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Start New Chat',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff075E54),
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildChatOption(
                    icon: Icons.qr_code_scanner,
                    title: 'Scan QR Code',
                    subtitle: 'Scan someone\'s QR code to connect',
                    onTap: () {
                      Navigator.pop(context);
                      if (widget.onNavigateToScan != null) {
                        widget.onNavigateToScan!();
                      }
                    },
                  ),
                  _buildChatOption(
                    icon: Icons.person_add,
                    title: 'Add by User ID',
                    subtitle: 'Enter someone\'s user ID to connect',
                    onTap: () {
                      Navigator.pop(context);
                      _showAddByIdDialog();
                    },
                  ),
                  _buildChatOption(
                    icon: Icons.group,
                    title: 'Join Public Room',
                    subtitle: 'Join a public chat room',
                    onTap: () {
                      Navigator.pop(context);
                      _showPublicRoomsDialog();
                    },
                  ),
                  _buildChatOption(
                    icon: Icons.link,
                    title: 'Share Quick Connect',
                    subtitle: 'Generate a quick connect link',
                    onTap: () {
                      Navigator.pop(context);
                      _generateQuickConnect();
                    },
                  ),
                  SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.all(15),
        margin: EdgeInsets.only(bottom: 10),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Color(0xff075E54).withOpacity(0.1),
                borderRadius: BorderRadius.circular(25),
              ),
              child: Icon(icon, color: Color(0xff075E54), size: 24),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
          ],
        ),
      ),
    );
  }

  void _showAddByIdDialog() {
    final TextEditingController idController = TextEditingController();
    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Contact by ID'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: idController,
              decoration: InputDecoration(
                labelText: 'User ID',
                hintText: 'Enter user ID (e.g., user_123)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 15),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Display Name (optional)',
                hintText: 'Enter a name for this contact',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              print('Cancel button pressed');
              Navigator.pop(context);
            },
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              print('Add button pressed');
              final userId = idController.text.trim();
              final displayName = nameController.text.trim();

              print('User ID: $userId');
              print('Display Name: $displayName');

              if (userId.isNotEmpty) {
                try {
                  print('Calling _addChatById...');
                  await _addChatById(
                    userId,
                    displayName.isEmpty ? 'User $userId' : displayName,
                  );
                  print('Successfully added contact, closing dialog');
                  Navigator.pop(context);
                } catch (e) {
                  print('Error adding contact: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to add contact: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              } else {
                print('User ID is empty');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Please enter a User ID'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff075E54)),
            child: Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showPublicRoomsDialog() {
    final List<Map<String, String>> publicRooms = [
      {
        'id': 'general_chat',
        'name': 'General Chat',
        'description': 'Open discussion for everyone',
      },
      {
        'id': 'tech_talk',
        'name': 'Tech Talk',
        'description': 'Discuss technology and programming',
      },
      {
        'id': 'random_chat',
        'name': 'Random Chat',
        'description': 'Random conversations and fun',
      },
      {
        'id': 'help_support',
        'name': 'Help & Support',
        'description': 'Get help and support from others',
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join Public Room'),
        content: Container(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: publicRooms.length,
            itemBuilder: (context, index) {
              final room = publicRooms[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(0xff075E54),
                  child: Icon(Icons.group, color: Colors.white),
                ),
                title: Text(room['name']!),
                subtitle: Text(room['description']!),
                onTap: () async {
                  await _joinPublicRoom(room['id']!, room['name']!);
                  Navigator.pop(context);
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
      ),
    );
  }

  Future<void> _addChatById(String userId, String displayName) async {
    try {
      print('Adding contact: $userId with name: $displayName');

      // Check if chat already exists
      final existingChats = await _databaseService.getAllChats();
      final existingChat = existingChats.where((chat) => chat.id == userId);

      if (existingChat.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Contact already exists!'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final newChat = ChatModel(
        id: userId,
        name: displayName,
        lastMessage: 'Connected by User ID',
        lastMessageTime: DateTime.now(),
        isOnline: false,
      );

      await _databaseService.insertOrUpdateChat(newChat);
      print('Contact inserted successfully');

      await _refreshChats();
      print('Chats refreshed');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Contact "$displayName" added successfully!'),
          backgroundColor: Color(0xff075E54),
        ),
      );
    } catch (e) {
      print('Error in _addChatById: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add contact: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  Future<void> _joinPublicRoom(String roomId, String roomName) async {
    final roomChat = ChatModel(
      id: roomId,
      name: roomName,
      lastMessage: 'Welcome to $roomName!',
      lastMessageTime: DateTime.now(),
      isOnline: true,
      isGroup: true,
    );

    await _databaseService.insertOrUpdateChat(roomChat);
    await _refreshChats();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Joined $roomName successfully!'),
        backgroundColor: Color(0xff075E54),
      ),
    );
  }

  void _generateQuickConnect() {
    final quickConnectId = 'quick_${DateTime.now().millisecondsSinceEpoch}';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quick Connect'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.link, size: 60, color: Color(0xff075E54)),
            SizedBox(height: 15),
            Text(
              'Share this ID with someone to start chatting:',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: SelectableText(
                quickConnectId,
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(height: 15),
            Text(
              'Or scan this QR code:',
              style: TextStyle(color: Colors.grey[600]),
            ),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'QR Code\n(Would show actual QR here)',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[500]),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              // Copy to clipboard logic would go here
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Quick connect ID copied to clipboard!'),
                  backgroundColor: Color(0xff075E54),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff075E54)),
            child: Text('Copy ID', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              'No Chats Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Scan a QR code to start your first conversation',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: () {
                // Navigate to scan tab using callback
                if (widget.onNavigateToScan != null) {
                  widget.onNavigateToScan!();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Please tap the "Scan" tab at the bottom to scan QR codes',
                      ),
                      backgroundColor: Color(0xff075E54),
                    ),
                  );
                }
              },
              icon: Icon(Icons.qr_code_scanner),
              label: Text('Scan QR Code'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff075E54),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatTile(ChatModel chat) {
    return Dismissible(
      key: Key(chat.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        color: Colors.red,
        child: Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Delete Chat'),
              content: Text('Are you sure you want to delete this chat?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text('Delete'),
                ),
              ],
            );
          },
        );
      },
      onDismissed: (direction) async {
        await _databaseService.deleteChat(chat.id);
        setState(() {
          chats.removeWhere((c) => c.id == chat.id);
        });
        NotificationService.showSuccess(context, 'Chat deleted');
      },
      child: ListTile(
        leading: CircleAvatar(
          radius: 25,
          backgroundColor: Color(0xff075E54),
          child: chat.profileImage.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(25),
                  child: Image.network(
                    chat.profileImage,
                    width: 50,
                    height: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(Icons.person, color: Colors.white, size: 30);
                    },
                  ),
                )
              : Icon(Icons.person, color: Colors.white, size: 30),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                chat.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            if (chat.isOnline)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
        subtitle: Text(
          chat.lastMessage,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(chat.lastMessageTime),
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
            SizedBox(height: 5),
            Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
        onTap: () async {
          // Create a source chat representing the current user
          final sourceChat = ChatModel(
            id: 'current_user_123', // In real app, get from user session
            name: 'You',
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            isOnline: true,
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  IndividualPage(chatModel: chat, sourceChat: sourceChat),
            ),
          ).then((_) {
            _refreshChats(); // Refresh chats when returning from chat page
          });
        },
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return DateFormat('EEEE').format(dateTime);
      } else {
        return DateFormat('dd/MM/yy').format(dateTime);
      }
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
