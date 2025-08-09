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
}

