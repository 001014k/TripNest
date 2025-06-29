class MarkerModel {
  final String id;
  final String title;
  final String keyword;
  final String address;
  final double lat;
  final double lng;
  final String markerImagePath;

  MarkerModel({
    required this.id,
    required this.title,
    required this.keyword,
    required this.address,
    required this.lat,
    required this.lng,
    required this.markerImagePath,
  });

  // Supabase에서 받은 Map<String, dynamic>용
  factory MarkerModel.fromMap(Map<String, dynamic> data) {
    return MarkerModel(
      id: data['id'] as String,
      title: data['title'] ?? 'No Title',
      keyword: data['keyword'] ?? 'default',
      address: data['address'] ?? 'No Address',
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      markerImagePath: data['markerImagePath'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'keyword': keyword,
      'address': address,
      'lat': lat,
      'lng': lng,
      'markerImagePath': markerImagePath,
    };
  }
}
