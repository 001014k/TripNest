import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkerCreationScreenViewModel extends ChangeNotifier {

  Map<String, IconData> get keywordIcons => _keywordIcons;

  final Map<String, IconData> _keywordIcons = {
    '카페': Icons.local_cafe,
    '호텔': Icons.hotel,
    '사진': Icons.camera_alt,
    '음식점': Icons.restaurant,
    '전시회': Icons.art_track,
  };

  // 새 마커 생성
  void saveMarker(Marker marker, String keyword, String markerImagePath) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final address = await getAddressFromCoordinates(
        marker.position.latitude,
        marker.position.longitude,
      );

      final response = await Supabase.instance.client
          .from('user_markers')
          .insert({
        'id': marker.markerId.value,
        'user_id': user.id,
        'title': marker.infoWindow.title,
        'snippet': marker.infoWindow.snippet,
        'lat': marker.position.latitude,
        'lng': marker.position.longitude,
        'address': address,
        'keyword': keyword,
        'marker_image_path': markerImagePath,
      });

      if (response.error != null) {
        print('Error saving marker: ${response.error!.message}');
      }
    }
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      List<geocoding.Placemark> placemarks =
          await geocoding.placemarkFromCoordinates(
        latitude,
        longitude,
      );
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.country ?? ''} ${placemark.administrativeArea ?? ''} ${placemark.locality ?? ''} ${placemark.street ?? ''}';
      }
      return 'Unknown Address';
    } catch (e) {
      print('Error getting address: $e');
      return 'Error fetching address'; // Error message
    }
  }
}
