class SharedLinkModel {
  final String? id;           // nullable로 변경
  final String userId;
  final String url;
  final DateTime createdAt;

  SharedLinkModel({
    this.id,                 // nullable이므로 required 제거
    required this.userId,
    required this.url,
    required this.createdAt,
  });

  factory SharedLinkModel.fromMap(Map<String, dynamic> map) {
    return SharedLinkModel(
      id: map['id'] as String?,  // null 가능
      userId: map['user_id'] as String,
      url: map['url'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id,  // 제거: insert 시 자동 생성되므로 제외
      'user_id': userId,
      'url': url,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
