import 'package:google_maps_flutter/google_maps_flutter.dart';

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

  // Google Maps의 Marker 타입으로 변환하는 메서드 추가
  Marker toGoogleMarker() {
    return Marker(
      markerId: MarkerId(id),
      position: LatLng(lat, lng),
      infoWindow: InfoWindow(
        title: title,
        snippet: address,
      ),
      // 필요하면 아이콘, onTap 콜백 등 추가 가능
    );
  }
}
