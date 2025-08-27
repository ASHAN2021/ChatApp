import 'package:flutter/material.dart';
import '../Services/qr_service.dart';
import '../Services/database_service.dart';
import '../Services/notification_service.dart';
import '../CustomUI/qr_scanner_widget.dart';
import '../Model/chat_model.dart';
import '../Screens/individual_page.dart';

class ScanTab extends StatefulWidget {
  @override
  _ScanTabState createState() => _ScanTabState();
}

class _ScanTabState extends State<ScanTab> {
  final QRService _qrService = QRService();
  final DatabaseService _databaseService = DatabaseService();
  bool isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Instructions
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(20),
            color: Color(0xff075E54),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white, size: 40),
                  SizedBox(height: 10),
                  Text(
                    'Scan QR Code',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Point your camera at a QR code to connect',
                    style: TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                ],
              ),
            ),
          ),

          // QR Scanner
          Expanded(
            child: Stack(
              children: [
                QRScannerWidget(onQRCodeScanned: _handleQRCodeScanned),
                if (isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xff25D366),
                            ),
                          ),
                          SizedBox(height: 20),
                          Text(
                            'Processing QR Code...',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Instructions
          Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Color(0xff075E54)),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Make sure the QR code is clearly visible and well-lit',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 15),
                // Manual input option for testing
                Container(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _showManualInputDialog,
                    icon: Icon(Icons.keyboard),
                    label: Text('Enter QR Code Manually'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xff075E54),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleQRCodeScanned(String qrData) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      if (_qrService.isValidQRData(qrData)) {
        final chat = await _qrService.processScannedQR(qrData);
        final currentUser = await _databaseService.getCurrentUser();

        if (chat != null && currentUser != null) {
          // Create source chat model from current user
          final sourceChat = ChatModel(
            id: currentUser.id,
            name: currentUser.name,
            lastMessage: '',
            lastMessageTime: DateTime.now(),
            profileImage: currentUser.profileImage,
            isOnline: true,
          );

          NotificationService.showSuccess(
            context,
            'Connected to ${chat.name}!',
          );

          // Navigate directly to individual chat page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  IndividualPage(chatModel: chat, sourceChat: sourceChat),
            ),
          );
        } else {
          NotificationService.showError(
            context,
            'Failed to connect. Please try again.',
          );
        }
      } else {
        NotificationService.showError(
          context,
          'Invalid QR code. Please scan a valid QR Chat code.',
        );
      }
    } catch (e) {
      NotificationService.showError(
        context,
        'Error processing QR code. Please try again.',
      );
      print('QR scan error: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });

      // Add delay before allowing next scan
      await Future.delayed(Duration(seconds: 2));
    }
  }

  void _showManualInputDialog() {
    final TextEditingController qrController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Enter QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'For testing purposes, you can manually enter QR code data:',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            SizedBox(height: 15),
            TextField(
              controller: qrController,
              decoration: InputDecoration(
                labelText: 'QR Code Data',
                hintText: 'Paste or type QR code content',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final qrData = qrController.text.trim();
              if (qrData.isNotEmpty) {
                Navigator.pop(context);
                _handleQRCodeScanned(qrData);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xff075E54)),
            child: Text('Process', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
