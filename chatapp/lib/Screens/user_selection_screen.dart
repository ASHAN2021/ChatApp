import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../Model/user_model.dart';
import 'home_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  List<UserModel> users = [];
  bool isLoading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    loadUsers();
  }

  Future<void> loadUsers() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      // Try multiple server addresses for better connectivity
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
          print("🔄 Trying to connect to: $url");
          response = await http
              .get(
                Uri.parse("$url/api/users"),
                headers: {'Content-Type': 'application/json'},
              )
              .timeout(Duration(seconds: 5));

          if (response.statusCode == 200) {
            print("✅ Successfully connected to: $url");
            break;
          }
        } catch (e) {
          print("❌ Failed to connect to $url: $e");
          continue;
        }
      }

      if (response == null || response.statusCode != 200) {
        throw Exception(
          'Unable to connect to server. Please check if the server is running.',
        );
      }

      final List<dynamic> userData = json.decode(response.body);
      setState(() {
        users = userData.map((user) => UserModel.fromJson(user)).toList();
        isLoading = false;
      });

      print("👥 Loaded ${users.length} users");
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
      print("❌ Error loading users: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select User',
          style: TextStyle(
            color: Colors.white,
            fontSize: 19,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0xff075E54),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.white),
            onPressed: loadUsers,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff075E54), Color(0xff128C7E)],
          ),
        ),
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading users...',
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              )
            : error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'Error: $error',
                        style: TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: loadUsers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Color(0xff075E54),
                        padding: EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : users.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.people_outline, color: Colors.white, size: 64),
                    SizedBox(height: 16),
                    Text(
                      'No users found',
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please check your server connection',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: EdgeInsets.only(bottom: 12),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      leading: CircleAvatar(
                        radius: 30,
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              )
                            : null,
                      ),
                      title: Text(
                        user.name,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 4),
                          Text(
                            user.mobile,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: user.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                ),
                              ),
                              SizedBox(width: 6),
                              Text(
                                user.isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: user.isOnline
                                      ? Colors.green
                                      : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xff075E54),
                        size: 24,
                      ),
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HomeScreen(currentUser: user),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      ),
    );
  }
}
