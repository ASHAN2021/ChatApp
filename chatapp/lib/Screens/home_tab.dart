import 'package:flutter/material.dart';
import 'scan_tab.dart';

class HomeTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome section
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xff075E54), Color(0xff128C7E)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.waving_hand, color: Colors.yellow, size: 30),
                    SizedBox(width: 10),
                    Text(
                      'Welcome!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10),
                Text(
                  'Connect instantly with anyone using QR codes. No contacts needed!',
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),

          SizedBox(height: 30),

          // App description
          Text(
            'About QR Chat',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff075E54),
            ),
          ),

          SizedBox(height: 15),

          _buildFeatureCard(
            Icons.qr_code_scanner,
            'Instant Connection',
            'Scan someone\'s QR code or let them scan yours to start chatting immediately.',
            Colors.blue,
          ),

          SizedBox(height: 15),

          _buildFeatureCard(
            Icons.security,
            'Temporary & Secure',
            'Chat sessions are temporary and private. No data is stored permanently.',
            Colors.orange,
          ),

          SizedBox(height: 15),

          _buildFeatureCard(
            Icons.group,
            'No Contact Lists',
            'Meet new people without needing their phone numbers or contact details.',
            Colors.purple,
          ),

          SizedBox(height: 30),

          // Quick scan button
          Container(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ScanTab()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xff25D366),
                foregroundColor: Colors.white,
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code_scanner, size: 28),
                  SizedBox(width: 10),
                  Text(
                    'Scan QR Code',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 30),

          // How it works section
          Text(
            'How it works',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xff075E54),
            ),
          ),

          SizedBox(height: 15),

          _buildStepCard(
            1,
            'Generate QR Code',
            'Go to Profile tab and show your QR code',
          ),
          SizedBox(height: 10),
          _buildStepCard(
            2,
            'Scan QR Code',
            'Use Scan tab to scan someone\'s QR code',
          ),
          SizedBox(height: 10),
          _buildStepCard(
            3,
            'Start Chatting',
            'Begin your conversation instantly',
          ),

          SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    IconData icon,
    String title,
    String description,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff075E54),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard(int step, String title, String description) {
    return Container(
      padding: EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Color(0xff075E54).withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Color(0xff075E54).withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: Color(0xff075E54),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff075E54),
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
