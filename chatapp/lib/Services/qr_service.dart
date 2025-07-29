import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../Model/user_model.dart';
import '../Model/chat_model.dart';
import 'database_service.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final Uuid _uuid = Uuid();

  // Generate QR data for current user
  Future<String> generateQRData() async {
    final user = await _databaseService.getCurrentUser();
    if (user == null) return '';

    final qrData = {
      'userId': user.id,
      'userName': user.name,
      'profileImage': user.profileImage,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    return jsonEncode(qrData);
  }

  // Parse scanned QR data and create chat
  Future<ChatModel?> processScannedQR(String qrData) async {
    try {
      final data = jsonDecode(qrData);

      // Validate QR data structure
      if (!data.containsKey('userId') || !data.containsKey('userName')) {
        return null;
      }

      final chatId = _uuid.v4();
      final chat = ChatModel(
        id: chatId,
        name: data['userName'],
        lastMessage: 'Connected via QR code',
        lastMessageTime: DateTime.now(),
        profileImage: data['profileImage'] ?? '',
        isOnline: true,
      );

      // Save chat to database
      await _databaseService.insertOrUpdateChat(chat);

      return chat;
    } catch (e) {
      print('Error processing QR data: $e');
      return null;
    }
  }

  // Check if QR data is valid
  bool isValidQRData(String qrData) {
    try {
      final data = jsonDecode(qrData);
      return data.containsKey('userId') && data.containsKey('userName');
    } catch (e) {
      return false;
    }
  }

  // Generate chat ID for two users
  String generateChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
