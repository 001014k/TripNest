import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:convert';
import 'package:http/http.dart' as http;

final supabase = Supabase.instance.client;

// UserService: 사용자 통계 조회
class UserService {
  /// 사용자 통계 정보 반환 (user_markers, lists, bookmarks)
  Future<Map<String, int>> getUserStats(String userId) async {
    final markers = await supabase
        .from('user_markers')
        .select('id')
        .eq('user_id', userId);
    final lists = await supabase
        .from('lists')
        .select('id')
        .eq('user_id', userId);
    final bookmarks = await supabase
        .from('bookmarks')
        .select('id')
        .eq('user_id', userId);

    return {
      'markers': (markers as List).length,
      'lists': (lists as List).length,
      'bookmarks': (bookmarks as List).length,
    };
  }

  /// 현재 사용자 리스트 가져오기
  Future<List<Map<String, dynamic>>> getUserLists() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    final response = await supabase
        .from('lists')
        .select()
        .eq('user_id', user.id);

    return List<Map<String, dynamic>>.from(response);
  }
}

// BookmarkService: 리스트에 저장된 마커 조회
class BookmarkService {
  /// 리스트에 속한 마커 반환
  Future<List<Marker>> getMarkersForList(String userId, String listId, Function(MarkerId) onTap) async {
    final response = await supabase
        .from('list_bookmarks')
        .select()
        .eq('list_id', listId);

    return (response as List).map((data) {
      return Marker(
        markerId: MarkerId(data['id']),
        position: LatLng(data['lat'], data['lng']),
        infoWindow: InfoWindow(
          title: data['title'] ?? '제목 없음',
          snippet: data['snippet'] ?? '설명 없음',
        ),
        onTap: () => onTap(MarkerId(data['id'])),
      );
    }).toList();
  }
}

// UserListService: 사용자 리스트 조회
class UserListService {
  Future<List<Map<String, dynamic>>> fetchUserLists(String userId) async {
    final response = await supabase
        .from('lists')
        .select()
        .eq('user_id', userId);
    return List<Map<String, dynamic>>.from(response);
  }
}

// SearchService: Google Places API와 지오코딩 검색
class SearchService {
  final String apiKey;

  SearchService({required this.apiKey});

  /// Google Places API 검색
  Future<List<Marker>> searchPlacesWithQuery(String query) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText?&key=$apiKey');

    final requestBody = json.encode({
      "textQuery": query,
      "languageCode": "ko",
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location'
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['places'] != null && data['places'] is List) {
        return (data['places'] as List).map<Marker>((place) {
          final displayName = place['displayName']['text'];
          final formattedAddress = place['formattedAddress'];
          final lat = place['location']['latitude'];
          final lng = place['location']['longitude'];
          final placeId = place['place_id'] ?? displayName;

          return Marker(
            markerId: MarkerId(placeId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: displayName,
              snippet: formattedAddress,
            ),
          );
        }).toList();
      }
    }
    return [];
  }

  /// 지오코딩을 이용한 검색
  Future<Marker?> geocodeSearch(String query) async {
    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Marker(
          markerId: MarkerId('searchLocation'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: query),
        );
      }
    } catch (_) {}
    return null;
  }
}
