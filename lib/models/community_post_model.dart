class CommunityPost {
  const CommunityPost({
    required this.id,
    required this.title,
    required this.content,
    required this.destination,
    required this.authorId,
    required this.authorNickname,
    required this.createdAt,
    this.markerId,
    this.placeTitle,
    this.placeAddress,
    this.placeCategory,
    this.placeLatitude,
    this.placeLongitude,
    this.placeImagePath,
  });

  final String id;
  final String title;
  final String content;
  final String? destination;
  final String authorId;
  final String authorNickname;
  final DateTime createdAt;
  final String? markerId;
  final String? placeTitle;
  final String? placeAddress;
  final String? placeCategory;
  final double? placeLatitude;
  final double? placeLongitude;
  final String? placeImagePath;

  bool get isMarkerShare => placeTitle != null && placeTitle!.isNotEmpty;

  factory CommunityPost.fromMap(Map<String, dynamic> data) {
    final profile = data['profiles'];
    final nickname = profile is Map<String, dynamic>
        ? profile['nickname']?.toString().trim()
        : null;

    return CommunityPost(
      id: data['id'].toString(),
      title: data['title']?.toString() ?? '',
      content: data['content']?.toString() ?? '',
      destination: data['destination']?.toString(),
      authorId: data['author_id'].toString(),
      authorNickname: nickname == null || nickname.isEmpty ? '여행자' : nickname,
      createdAt: DateTime.tryParse(data['created_at']?.toString() ?? '') ??
          DateTime.now(),
      markerId: data['marker_id']?.toString(),
      placeTitle: data['place_title']?.toString(),
      placeAddress: data['place_address']?.toString(),
      placeCategory: data['place_category']?.toString(),
      placeLatitude: (data['place_lat'] as num?)?.toDouble(),
      placeLongitude: (data['place_lng'] as num?)?.toDouble(),
      placeImagePath: data['place_image_path']?.toString(),
    );
  }
}

class CommunityMarker {
  const CommunityMarker({
    required this.id,
    required this.title,
    required this.address,
    this.category,
    this.latitude,
    this.longitude,
    this.imagePath,
  });

  final String id;
  final String title;
  final String address;
  final String? category;
  final double? latitude;
  final double? longitude;
  final String? imagePath;

  factory CommunityMarker.fromMap(Map<String, dynamic> data) {
    return CommunityMarker(
      id: data['id'].toString(),
      title: data['title']?.toString() ?? '이름 없는 장소',
      address: data['address']?.toString() ?? '주소 정보 없음',
      category: data['keyword']?.toString(),
      latitude: (data['lat'] as num?)?.toDouble(),
      longitude: (data['lng'] as num?)?.toDouble(),
      imagePath: data['marker_image_path']?.toString(),
    );
  }
}
