import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/user_service.dart';
import '../config.dart';

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
      } catch (e) {
        print('Error saving marker: $e');
      }
    }
  }



  Future<String> getAddressFromCoordinates(double latitude, double longitude) async {
    final apiKey = Config.googleMapsApiKey;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey&language=ko',
    );

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['status'] == 'OK') {
          final results = json['results'];
          if (results != null && results.isNotEmpty) {
            return results[0]['formatted_address'];
          }
        } else {
          print('Google Geocoding API Error: ${json['status']}');
        }
      } else {
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Exception during reverse geocoding: $e');
    }

    return '주소 정보를 불러올 수 없습니다';
  }
}
