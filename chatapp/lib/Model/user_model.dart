class UserModel {
  String id;
  String name;
  String profileImage;
  String qrCode;
  DateTime createdAt;
  String mobile;
  bool isOnline;
  DateTime? lastSeen;

  UserModel({
    required this.id,
    required this.name,
    this.profileImage = '',
    required this.qrCode,
    required this.createdAt,
    this.mobile = '',
    this.isOnline = false,
    this.lastSeen,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'qrCode': qrCode,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'mobile': mobile,
      'isOnline': isOnline ? 1 : 0,
      'lastSeen': lastSeen?.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      profileImage: map['profileImage'] ?? '',
      qrCode: map['qrCode'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
      ),
      mobile: map['mobile'] ?? '',
      isOnline: (map['isOnline'] ?? 0) == 1,
      lastSeen: map['lastSeen'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['lastSeen'])
          : null,
    );
  }

  // For server API responses
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      profileImage: json['profileImage'] ?? '',
      qrCode: json['qrCode'] ?? '',
      createdAt: DateTime.now(), // Default for server responses
      mobile: json['mobile'] ?? '',
      isOnline: (json['isOnline'] ?? 0) == 1,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'qrCode': qrCode,
      'mobile': mobile,
      'isOnline': isOnline ? 1 : 0,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }
}
