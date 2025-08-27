import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../Model/user_model.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';
import 'main_screen.dart';

class ProfileSetupScreen extends StatefulWidget {
  @override
  _ProfileSetupScreenState createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = Uuid();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xff075E54), Color(0xff128C7E)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 40),

                // Header
                Text(
                  'Set Up Your Profile',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(height: 10),

                Text(
                  'Enter your name to get started',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),

                SizedBox(height: 60),

                // Profile Avatar
                Container(
                  height: 120,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(60),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, size: 60, color: Color(0xff075E54)),
                ),

                SizedBox(height: 40),

                // Name Input
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 15,
                      ),
                      prefixIcon: Icon(
                        Icons.person_outline,
                        color: Color(0xff075E54),
                      ),
                    ),
                    style: TextStyle(fontSize: 16, color: Color(0xff075E54)),
                  ),
                ),

                SizedBox(height: 40),

                // Continue Button
                Container(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _setupProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Color(0xff075E54),
                      elevation: 5,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(27.5),
                      ),
                    ),
                    child: _isLoading
                        ? CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff075E54),
                            ),
                          )
                        : Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                Spacer(),

                // Info text
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white30),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.white70, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your name will be visible to people you chat with.',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _setupProfile() async {
    if (_nameController.text.trim().isEmpty) {
      NotificationService.showError(context, 'Please enter your name');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final userId = _uuid.v4();
      final user = UserModel(
        id: userId,
        name: _nameController.text.trim(),
        qrCode: userId, // Using userId as QR code for simplicity
        createdAt: DateTime.now(),
      );

      await _databaseService.insertUser(user);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isUserSetup', true);
      await prefs.setString('userId', userId);
      await prefs.setString('userName', user.name);

      NotificationService.showSuccess(context, 'Profile setup completed!');

      await Future.delayed(Duration(seconds: 1));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MainScreen()),
      );
    } catch (e) {
      NotificationService.showError(
        context,
        'Failed to setup profile. Please try again.',
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
