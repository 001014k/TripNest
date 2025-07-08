import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';

class MarkerCreationScreenViewModel extends ChangeNotifier {

  Map<String, IconData> get keywordIcons => _keywordIcons;

  final Map<String, IconData> _keywordIcons = {
    '카페': Icons.local_cafe,
    '호텔': Icons.hotel,
    '사진': Icons.camera_alt,
    '음식점': Icons.restaurant,
    '전시회': Icons.art_track,
  };

  List<Map<String, dynamic>> _lists = [];
  List<Map<String, dynamic>> get lists => _lists;


  Future<void> fetchUserLists() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final response = await supabase
          .from('lists')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _lists = (response as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      print('리스트 불러오기 실패: $e');
    }
  }


  // 새 마커 생성
  Future<void> saveMarker({
    required Marker marker,
    required String keyword,
    required String markerImagePath,
    String? listId,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final address = await getAddressFromCoordinates(
        marker.position.latitude,
        marker.position.longitude,
      );

      try {
        await Supabase.instance.client
            .from('user_markers')
            .insert({
          'id': marker.markerId.value,
          'user_id': user.id,
          'list_id': listId, // ✅ 리스트 ID 저장
          'title': marker.infoWindow.title,
          'snippet': marker.infoWindow.snippet,
          'lat': marker.position.latitude,
          'lng': marker.position.longitude,
          'address': address,
          'keyword': keyword,
        });
      } catch (e) {
        print('Error saving marker: $e');
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
