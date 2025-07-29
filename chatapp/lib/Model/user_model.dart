class UserModel {
  String id;
  String name;
  String profileImage;
  String qrCode;
  DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    this.profileImage = '',
    required this.qrCode,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'profileImage': profileImage,
      'qrCode': qrCode,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      profileImage: map['profileImage'] ?? '',
      qrCode: map['qrCode'],
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt']),
    );
  }
}
