import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/marker_model.dart';

class MarkerInfoViewModel extends ChangeNotifier {
  final String listId;
  List<MarkerModel> markers = [];
  bool isLoading = true;
  String? error;

  final supabase = Supabase.instance.client;

  MarkerInfoViewModel({required this.listId}) {
    loadMarkers();
  }

  Future<void> loadMarkers() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final data = await supabase
          .from('list_bookmarks')
          .select()
          .eq('list_id', listId)
          .order('sort_order', ascending: true);

      markers = (data as List)
          .map((json) => MarkerModel.fromMap(json as Map<String, dynamic>))
          .toList();

      isLoading = false;
    } catch (e) {
      error = 'Failed to load markers: $e';
      isLoading = false;
    }
    notifyListeners();
  }

  Future<void> deleteMarker(String markerId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      await supabase
          .from('list_bookmarks')
          .delete()
          .eq('id', markerId)
          .eq('user_id', user.id);

      markers.removeWhere((marker) => marker.id == markerId);
      notifyListeners();
    } catch (e) {
      error = 'Failed to delete marker: $e';
      notifyListeners();
    }
  }

  Future<Map<String, String>> fetchMarkerDetail(String markerId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return {
      'title': '제목 없음',
      'address': '주소 없음',
      'keyword': '키워드 없음',
    };

    try {
      final data = await Supabase.instance.client
          .from('user_markers')
          .select('title, address, keyword')
          .eq('id', markerId)
          .eq('user_id', user.id)
          .maybeSingle();

      return {
        'title': data?['title'] ?? '제목 없음',
        'address': data?['address'] ?? '주소 없음',
        'keyword': data?['keyword'] ?? '키워드 없음',
      };
    } catch (e) {
      print('마커 정보 로딩 오류: $e');
      return {
        'title': '오류 발생',
        'address': '',
        'keyword': '',
      };
    }
  }
}
