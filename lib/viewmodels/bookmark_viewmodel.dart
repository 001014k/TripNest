import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookmarkViewmodel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  Future<List<Marker>> loadBookmarks() async {
    final user = supabase.auth.currentUser;
    if (user == null) return [];

    try {
      final data = await supabase
          .from('bookmarks')
          .select()
          .eq('user_id', user.id);

      return (data as List<dynamic>).map((json) {
        String title = json['title'] ?? '이름 없음';
        String keyword = json['keyword'] ?? '키워드 없음';
        String address = json['address'] ?? '주소 없음';
        final lat = (json['lat'] as num?)?.toDouble() ?? 0.0;
        final lng = (json['lng'] as num?)?.toDouble() ?? 0.0;

        return Marker(
          markerId: MarkerId(json['id']),
          position: LatLng(lat, lng),
          infoWindow: InfoWindow(
            title: title,
            snippet: '$keyword\n$address',
          ),
        );
      }).toList();
    } catch (e) {
      print('Failed to load bookmarks: $e');
      return [];
    }
  }
}
