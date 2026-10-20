import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/geocoding_service.dart';
import '../services/user_service.dart';

class MarkerCreationScreenViewModel extends ChangeNotifier {
  final GeocodingService _geocodingService = const GeocodingService();
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
          .select('id, name, list_bookmarks(title)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _lists = (response as List).cast<Map<String, dynamic>>();
      notifyListeners();
    } catch (e) {
      debugPrint('리스트 불러오기 실패: $e');
      rethrow;
    }
  }

  Future<String> createList(String name) async {
    final user = supabase.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    final result = await supabase
        .from('lists')
        .insert({
          'user_id': user.id,
          'name': name,
          'created_at': DateTime.now().toIso8601String(),
        })
        .select('id')
        .single();
    return result['id'].toString();
  }

  // 새 마커 생성
  Future<bool> saveMarker({
    required Marker marker,
    required String keyword,
    required String markerImagePath,
    required String address,
    String? listId,
  }) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('user_markers').insert({
          'id': marker.markerId.value,
          'user_id': user.id,
          'list_id': listId,
          'title': marker.infoWindow.title,
          'snippet': marker.infoWindow.snippet,
          'lat': marker.position.latitude,
          'lng': marker.position.longitude,
          'address': address,
          'keyword': keyword,
        });
        return true;
      } catch (e) {
        debugPrint('Error saving marker: $e');
      }
    }
    return false;
  }

  Future<String> getAddressFromCoordinates(
      double latitude, double longitude) async {
    try {
      return await _geocodingService.findAddress(latitude, longitude) ??
          '주소 정보를 불러올 수 없습니다';
    } catch (e) {
      debugPrint('Exception during reverse geocoding: $e');
      return '주소 정보를 불러올 수 없습니다';
    }
  }
}
