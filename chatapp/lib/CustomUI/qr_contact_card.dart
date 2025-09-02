import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/services.dart';
import '../Model/user_model.dart';
import '../Services/qr_service.dart';
import '../Services/notification_service.dart';

class QRContactCard extends StatefulWidget {
  final UserModel user;
  final bool showActions;

  const QRContactCard({
    Key? key,
    required this.user,
    this.showActions = true,
  }) : super(key: key);

  @override
  _QRContactCardState createState() => _QRContactCardState();
}

class _QRContactCardState extends State<QRContactCard>
    with SingleTickerProviderStateMixin {
  final QRService _qrService = QRService();
  String qrData = '';
  bool isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _generateQRCode();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    try {
      final qrString = await _qrService.generateQRData();
      setState(() {
        qrData = qrString;
        isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      print('Error generating QR code: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _refreshQRCode() async {
    setState(() {
      isLoading = true;
    });
    await _generateQRCode();
    NotificationService.showSuccess(context, 'QR code refreshed!');
  }

  Future<void> _copyQRData() async {
    if (qrData.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: qrData));
      NotificationService.showSuccess(context, 'QR data copied to clipboard');
    }
  }

  void _showFullScreenQR() {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          margin: EdgeInsets.all(20),
          padding: EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xff075E54),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.qr_code_2, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scan to Connect',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xff075E54),
                          ),
                        ),
                        Text(
                          widget.user.name,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.grey[600]),
                  ),
                ],
              ),
              
              SizedBox(height: 30),

              // Large QR Code
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: QrImageView(
                  data: qrData,
                  version: QrVersions.auto,
                  size: 250.0,
                  foregroundColor: Color(0xff075E54),
                  backgroundColor: Colors.white,
                ),
              ),

              SizedBox(height: 30),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _copyQRData();
                      },
                      icon: Icon(Icons.copy, size: 18),
                      label: Text('Copy'),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xff075E54),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _refreshQRCode();
                      },
                      icon: Icon(Icons.refresh, size: 18),
                      label: Text('Refresh'),
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
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) => Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xff075E54),
                Color(0xff128C7E),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Color(0xff075E54).withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.qr_code_2,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'My QR Contact',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Share this code to connect instantly',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.showActions)
                      IconButton(
                        onPressed: _refreshQRCode,
                        icon: Icon(Icons.refresh, color: Colors.white),
                        tooltip: 'Refresh QR Code',
                      ),
                  ],
                ),

                SizedBox(height: 20),

                // QR Code Container
                GestureDetector(
                  onTap: _showFullScreenQR,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // User Info
                        Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Color(0xff075E54),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.user.name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xff075E54),
                                    ),
                                  ),
                                  Text(
                                    'Tap to view full screen',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 16),

                        // QR Code
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: isLoading
                              ? Container(
                                  height: 150,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Color(0xff075E54),
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Generating...',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : qrData.isNotEmpty
                                  ? QrImageView(
                                      data: qrData,
                                      version: QrVersions.auto,
                                      size: 150.0,
                                      foregroundColor: Color(0xff075E54),
                                      backgroundColor: Colors.white,
                                    )
                                  : Container(
                                      height: 150,
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.error_outline,
                                              color: Colors.red,
                                              size: 30,
                                            ),
                                            SizedBox(height: 4),
                                            Text(
                                              'Failed to generate',
                                              style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 10,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                        ),

                        SizedBox(height: 12),

                        // Info Banner
                        Container(
                          padding: EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Color(0xff25D366).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: Color(0xff25D366),
                                size: 14,
                              ),
                              SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  'Others can scan this to start chatting with you',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Color(0xff25D366),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                if (widget.showActions) ...[
                  SizedBox(height: 16),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _copyQRData,
                          icon: Icon(Icons.copy, size: 16),
                          label: Text('Copy'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xff075E54),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _showFullScreenQR,
                          icon: Icon(Icons.fullscreen, size: 16),
                          label: Text('Full View'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Color(0xff075E54),
                            elevation: 0,
                            padding: EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
