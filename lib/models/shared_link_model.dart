class SharedLinkModel {
  final String id;
  final String userId;
  final String url;
  final String? title;
  final String? source;
  final DateTime createdAt;

  SharedLinkModel({
    required this.id,
    required this.userId,
    required this.url,
    this.title,
    this.source,
    required this.createdAt,
  });

  factory SharedLinkModel.fromMap(Map<String, dynamic> map) {
    return SharedLinkModel(
      id: map['id'],
      userId: map['user_id'],
      url: map['url'],
      title: map['title'],
      source: map['source'],
      createdAt: DateTime.parse(map['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'url': url,
      'title': title,
      'source': source,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
