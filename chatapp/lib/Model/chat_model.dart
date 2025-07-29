class ChatModel {
  String id;
  String name;
  String lastMessage;
  DateTime lastMessageTime;
  String profileImage;
  bool isOnline;
  String? currentMessage;
  bool select;
  bool isGroup;
  String? time;

  ChatModel({
    required this.id,
    required this.name,
    required this.lastMessage,
    required this.lastMessageTime,
    this.profileImage = '',
    this.isOnline = false,
    this.currentMessage,
    this.select = false,
    this.isGroup = false,
    this.time,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.millisecondsSinceEpoch,
      'profileImage': profileImage,
      'isOnline': isOnline ? 1 : 0,
      'isGroup': isGroup ? 1 : 0,
    };
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      map['lastMessageTime'],
    );
    return ChatModel(
      id: map['id'],
      name: map['name'],
      lastMessage: map['lastMessage'],
      lastMessageTime: dateTime,
      profileImage: map['profileImage'] ?? '',
      isOnline: map['isOnline'] == 1,
      isGroup: (map['isGroup'] ?? 0) == 1, // Handle null values
      time:
          "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}",
    );
  }
}
