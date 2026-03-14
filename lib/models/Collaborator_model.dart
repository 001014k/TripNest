class Collaborator {
  final String userId;
  final String nickname;
  final String role;  // 'editor' | 'viewer' 등

  Collaborator({
    required this.userId,
    required this.nickname,
    required this.role,
  });
}