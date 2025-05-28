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

  factory MarkerModel.fromFirestore(String id, Map<String, dynamic> data) {
    return MarkerModel(
      id: id,
      title: data['title'] ?? 'No Title',
      keyword: data['keyword'] ?? 'default',
      address: data['address'] ?? 'No Address',
      lat: data['lat'] ?? 0.0,
      lng: data['lng'] ?? 0.0,
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
