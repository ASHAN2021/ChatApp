import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../Model/chat_model.dart';
import 'database_service.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final DatabaseService _databaseService = DatabaseService();

  // Generate enhanced QR data for current user
  Future<String> generateQRData() async {
    final user = await _databaseService.getCurrentUser();
    if (user == null) return '';

    // Create unique identifier for this QR code
    final uniqueId = _generateUniqueIdentifier(user.id);
    
    final qrData = {
      'type': 'QR_CHAT_CONTACT',
      'version': '1.0',
      'userId': user.id,
      'userName': user.name,
      'profileImage': user.profileImage,
      'mobile': user.mobile,
      'qrId': uniqueId,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'appId': 'qr_chat_app',
    };

    return jsonEncode(qrData);
  }

  // Generate unique identifier for QR code
  String _generateUniqueIdentifier(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final data = '$userId$timestamp';
    final bytes = utf8.encode(data);
    final digest = sha256.convert(bytes);
    return digest.toString().substring(0, 16);
  }

  // Parse QR data from string
  Map<String, dynamic>? parseQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      if (_isValidQRStructure(data)) {
        return data;
      }
      return null;
    } catch (e) {
      print('Error parsing QR data: $e');
      return null;
    }
  }

  // Enhanced QR processing with better connection handling
  Future<ChatModel?> processScannedQR(String qrData) async {
    try {
      final data = jsonDecode(qrData);

      // Validate QR data structure
      if (!_isValidQRStructure(data)) {
        print('Invalid QR structure');
        return null;
      }

      final scannedUserId = data['userId'];
      final scannedUserName = data['userName'];
      final scannedProfileImage = data['profileImage'] ?? '';

      // Get current user
      final currentUser = await _databaseService.getCurrentUser();
      if (currentUser == null) {
        print('No current user found');
        return null;
      }

      // Check if trying to scan own QR code
      if (scannedUserId == currentUser.id) {
        throw Exception('Cannot scan your own QR code');
      }

      // Generate deterministic chat ID for these two users
      final chatId = generateChatId(currentUser.id, scannedUserId);

      // Check if chat already exists
      final existingChat = await _databaseService.getChatById(chatId);
      if (existingChat != null) {
        return existingChat;
      }

      // Create new chat
      final newChat = ChatModel(
        id: chatId,
        name: scannedUserName,
        lastMessage: 'Connected via QR code 🔗',
        lastMessageTime: DateTime.now(),
        profileImage: scannedProfileImage,
        isOnline: true,
      );

      // Save chat to database
      await _databaseService.insertOrUpdateChat(newChat);

      print('Successfully created chat with ID: $chatId');
      return newChat;
    } catch (e) {
      print('Error processing QR data: $e');
      return null;
    }
  }

  // Validate QR data structure
  bool _isValidQRStructure(Map<String, dynamic> data) {
    return data.containsKey('type') &&
           data['type'] == 'QR_CHAT_CONTACT' &&
           data.containsKey('userId') &&
           data.containsKey('userName') &&
           data.containsKey('appId') &&
           data['appId'] == 'qr_chat_app';
  }

  // Check if QR data is valid (enhanced version)
  bool isValidQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      return _isValidQRStructure(data);
    } catch (e) {
      return false;
    }
  }

  // Generate deterministic chat ID for two users
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }

  // Check if QR code is expired (optional security feature)
  bool isQRCodeExpired(Map<String, dynamic> qrData) {
    if (!qrData.containsKey('timestamp')) return false;
    
    final timestamp = qrData['timestamp'] as int;
    final qrTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(qrTime);
    
    // QR codes expire after 24 hours for security
    return difference.inHours > 24;
  }
}
