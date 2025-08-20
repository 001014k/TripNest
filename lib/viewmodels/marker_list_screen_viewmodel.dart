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
          .select('id, title, address, keyword, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      markers = List<Map<String, dynamic>>.from(data);
    } catch (e) {
      print('fetchMarkers error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteMarker(BuildContext context, String markerId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final response = await supabase
          .from('user_markers')
          .delete()
          .eq('id', markerId)
          .eq('user_id', user.id);

      // 성공적으로 삭제되면 리스트에서 제거
      markers.removeWhere((m) => m['id'] == markerId);
      notifyListeners();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제되었습니다.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('삭제 실패: $e')),
      );
    }
  }
}