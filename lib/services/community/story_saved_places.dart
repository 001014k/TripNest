import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/community/community_post_model.dart';

class StorySavedPlaces {
  static final revision = ValueNotifier<int>(0);
  static List<Map<String, dynamic>> _markers = [];
  static String? _userId;
  static Future<void>? _pending;

  static Future<void> refresh() => _pending ??= _load().whenComplete(() => _pending = null);

  static Future<void> _load() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser?.id;
    if (_userId != user) {
      _markers = [];
      _userId = user;
    }
    try {
      final rows = user == null ? <Map<String, dynamic>>[] :
          await client.from('user_markers').select('id,title,address,lat,lng').eq('user_id', user);
      if (client.auth.currentUser?.id != user) return;
      _markers = rows;
    } catch (_) {
      // Preserve the last successful snapshot on a transient failure.
    }
    revision.value++;
  }

  static String _normalize(String? value) =>
      (value ?? '').trim().toLowerCase().replaceAll(RegExp(r'\s+'), '');

  static bool matches(CommunityPost post, Map<String, dynamic> marker) {
    if (post.markerId != null && post.markerId == marker['id']) return true;
    if (_normalize(post.placeTitle ?? post.title) != _normalize(marker['title']?.toString())) return false;
    final lat = (marker['lat'] as num?)?.toDouble();
    final lng = (marker['lng'] as num?)?.toDouble();
    if (post.placeLatitude != null && post.placeLongitude != null && lat != null && lng != null) {
      return (lat - post.placeLatitude!).abs() <= .00001 &&
          (lng - post.placeLongitude!).abs() <= .00001;
    }
    final address = _normalize(post.placeAddress);
    return address.isNotEmpty && address == _normalize(marker['address']?.toString());
  }

  static bool contains(CommunityPost post) =>
      _userId == Supabase.instance.client.auth.currentUser?.id &&
      _markers.any((marker) => matches(post, marker));
}
