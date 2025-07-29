import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Model/user_model.dart';
import '../Services/database_service.dart';
import '../Services/qr_service.dart';
import '../Services/notification_service.dart';
import 'welcome_screen.dart';

class ProfileTab extends StatefulWidget {
  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  final DatabaseService _databaseService = DatabaseService();
  final QRService _qrService = QRService();
  UserModel? currentUser;
  String qrData = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _databaseService.getCurrentUser();
      if (user != null) {
        final qrString = await _qrService.generateQRData();
        setState(() {
          currentUser = user;
          qrData = qrString;
          isLoading = false;
        });
      } else {
        // No user found, check if setup was completed in SharedPreferences
        SharedPreferences prefs = await SharedPreferences.getInstance();
        bool isUserSetup = prefs.getBool('isUserSetup') ?? false;

        if (isUserSetup) {
          // User was setup but not in database (possibly due to reset)
          // Clear the setup flag and show setup option
          await prefs.setBool('isUserSetup', false);
        }

        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading user profile: $e');
      setState(() {
        isLoading = false;
      });
      NotificationService.showError(context, 'Failed to load profile');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (currentUser == null) {
      return _buildNoUserState();
    }

    return RefreshIndicator(
      onRefresh: _loadUserProfile,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 20),

            // Profile Picture and Name
            Column(
              children: [
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Color(0xff075E54),
                    borderRadius: BorderRadius.circular(50),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(Icons.person, size: 50, color: Colors.white),
                ),
                SizedBox(height: 15),
                Text(
                  currentUser!.name,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff075E54),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'QR Chat User',
                  style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),

            SizedBox(height: 40),

            // QR Code Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                  Text(
                    'Your QR Code',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff075E54),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Let others scan this code to start chatting with you',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 20),
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: qrData.isNotEmpty
                        ? QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 200.0,
                            foregroundColor: Color(0xff075E54),
                          )
                        : Container(
                            height: 200,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Color(0xff075E54).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Color(0xff075E54),
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'This QR code is unique to you',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xff075E54),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // User Info Section
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Profile Information',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xff075E54),
                    ),
                  ),
                  SizedBox(height: 15),
                  _buildInfoRow(Icons.person, 'Name', currentUser!.name),
                  SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.date_range,
                    'Member Since',
                    _formatDate(currentUser!.createdAt),
                  ),
                  SizedBox(height: 10),
                  _buildInfoRow(
                    Icons.qr_code,
                    'User ID',
                    currentUser!.id.substring(0, 8) + '...',
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Action Buttons
            Column(
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  title: 'Refresh QR Code',
                  onTap: () {
                    _loadUserProfile();
                    NotificationService.showInfo(context, 'QR Code refreshed');
                  },
                  color: Colors.blue,
                ),
                SizedBox(height: 15),
                _buildActionButton(
                  icon: Icons.delete_forever,
                  title: 'Clear All Chats',
                  onTap: _showClearChatsDialog,
                  color: Colors.orange,
                ),
                SizedBox(height: 15),
                _buildActionButton(
                  icon: Icons.logout,
                  title: 'Reset Profile',
                  onTap: _showResetProfileDialog,
                  color: Colors.red,
                ),
              ],
            ),

            SizedBox(height: 20),
          ],
        ), // End Column
      ), // End SingleChildScrollView
    ); // End RefreshIndicator
  }

  Widget _buildNoUserState() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 80, color: Colors.grey[400]),
            SizedBox(height: 20),
            Text(
              'No Profile Found',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Your profile may have been reset due to database changes.\nPlease set up your profile again.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey[500]),
            ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    setState(() {
                      isLoading = true;
                    });
                    await _loadUserProfile();
                  },
                  icon: Icon(Icons.refresh),
                  label: Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey[600],
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    // Clear user setup flag
                    SharedPreferences prefs =
                        await SharedPreferences.getInstance();
                    await prefs.setBool('isUserSetup', false);

                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => WelcomeScreen()),
                    );
                  },
                  icon: Icon(Icons.person_add),
                  label: Text('Setup Profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xff075E54),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Color(0xff075E54), size: 20),
        SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[800])),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Container(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Text(title),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  void _showClearChatsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Clear All Chats'),
          content: Text(
            'Are you sure you want to delete all chat history? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _databaseService.clearAllData();
                await _databaseService.insertUser(currentUser!);
                NotificationService.showSuccess(context, 'All chats cleared');
              },
              child: Text('Clear All'),
            ),
          ],
        );
      },
    );
  }

  void _showResetProfileDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Reset Profile'),
          content: Text(
            'Are you sure you want to reset your profile? This will delete all data and you\'ll need to set up again.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _resetProfile();
              },
              child: Text('Reset'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetProfile() async {
    try {
      await _databaseService.clearAllData();
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      NotificationService.showSuccess(context, 'Profile reset successfully');

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => WelcomeScreen()),
        (route) => false,
      );
    } catch (e) {
      NotificationService.showError(context, 'Failed to reset profile');
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}
