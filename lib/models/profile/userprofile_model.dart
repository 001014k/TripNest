class UserProfile {
  final String id;
  final String email;
  final String? nickname;

  UserProfile({required this.id, required this.email, this.nickname});

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'],
      email: map['email'],
      nickname: map['nickname'],
    );
  }
}
