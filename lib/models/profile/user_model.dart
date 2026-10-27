class UserModel {
  final String id;
  final String email;
  final String? nickname;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.email,
    this.nickname,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      email: map['email'] as String,
      nickname: map['nickname'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'nickname': nickname,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
