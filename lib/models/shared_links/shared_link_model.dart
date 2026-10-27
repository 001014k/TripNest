class SharedLinkModel {
  final String? id; // nullable로 변경
  final String userId;
  final String url;
  final String platform;
  final DateTime createdAt;
  final String? placeTitle;
  final String? placeAddress;
  final double? placeLatitude;
  final double? placeLongitude;

  SharedLinkModel({
    this.id, // nullable이므로 required 제거
    required this.userId,
    required this.url,
    required this.platform,
    required this.createdAt,
    this.placeTitle,
    this.placeAddress,
    this.placeLatitude,
    this.placeLongitude,
  });

  factory SharedLinkModel.fromMap(Map<String, dynamic> map) {
    return SharedLinkModel(
      id: map['id'] as String?, // null 가능
      userId: map['user_id'] as String,
      url: map['url'] as String,
      platform: map['platform'] ?? 'unknown',
      createdAt: DateTime.parse(map['created_at'] as String),
      placeTitle: map['place_title'] as String?,
      placeAddress: map['place_address'] as String?,
      placeLatitude: (map['place_latitude'] as num?)?.toDouble(),
      placeLongitude: (map['place_longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      // 'id': id,  // 제거: insert 시 자동 생성되므로 제외
      'user_id': userId,
      'url': url,
      'platform': platform,
      'created_at': createdAt.toIso8601String(),
      'place_title': placeTitle,
      'place_address': placeAddress,
      'place_latitude': placeLatitude,
      'place_longitude': placeLongitude,
    };
  }
}
