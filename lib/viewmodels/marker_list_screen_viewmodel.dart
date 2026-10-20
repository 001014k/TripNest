import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkerListViewModel extends ChangeNotifier {
  final SupabaseClient supabase;
  bool isLoading = false;
  List<Map<String, dynamic>> markers = [];

  MarkerListViewModel(this.supabase);

  Future<void> fetchMarkers() async {
    isLoading = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        markers = [];
        return;
      }

      final data = await supabase
          .from('user_markers')
          .select(
              'id, title, address, keyword, created_at, lat, lng, marker_image_path')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      markers = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('fetchMarkers error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteMarker(String markerId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      await supabase
          .from('user_markers')
          .delete()
          .eq('id', markerId)
          .eq('user_id', user.id);

      // 성공적으로 삭제되면 리스트에서 제거
      markers.removeWhere((m) => m['id'] == markerId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('deleteMarker error: $e');
      return false;
    }
  }
}
