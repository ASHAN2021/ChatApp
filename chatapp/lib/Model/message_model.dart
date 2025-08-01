class MessageModel {
  String id;
  String chatId;
  String senderId;
  String message;
  DateTime timestamp;
  bool isMe;
  bool isRead;
  String messageType; // text, image, video
  String path;
  String? time;
  bool isDelivered;
  bool isPending;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    required this.timestamp,
    required this.isMe,
    this.isRead = false,
    this.messageType = 'text',
    required this.path,
    this.time,
    this.isDelivered = false,
    this.isPending = false,
  });

  // Legacy constructor for backward compatibility
  MessageModel.legacy({
    String? type,
    String? message,
    required String path,
    String? time,
  }) : this(
         id: DateTime.now().millisecondsSinceEpoch.toString(),
         chatId: '',
         senderId: '',
         message: message ?? '',
         timestamp: DateTime.now(),
         isMe: true,
         messageType: type ?? 'text',
         path: path,
         time: time,
         isDelivered: false,
         isPending: false,
       );

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'chatId': chatId,
      'senderId': senderId,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'isMe': isMe ? 1 : 0,
      'isRead': isRead ? 1 : 0,
      'messageType': messageType,
      'path': path,
      'isDelivered': isDelivered ? 1 : 0,
      'isPending': isPending ? 1 : 0,
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      id: map['id'],
      chatId: map['chatId'],
      senderId: map['senderId'],
      message: map['message'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
      isMe: map['isMe'] == 1,
      isRead: map['isRead'] == 1,
      messageType: map['messageType'] ?? 'text',
      path: map['path'] ?? '',
      isDelivered: map['isDelivered'] == 1,
      isPending: map['isPending'] == 1,
    );
  }
}
