import '../infrastructure/async_ttl_cache.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../models/community/community_post_model.dart';
import '../places/geocoding_service.dart';

class CommunityNearbyService {
  CommunityNearbyService({Future<LatLng?> Function(String)? geocode})
      : _geocode = geocode ?? const GeocodingService().findCoordinates;
  final Future<LatLng?> Function(String) _geocode;
  final _cache = AsyncTtlCache<String, LatLng?>(
      ttl: const Duration(hours: 24), isEmpty: (value) => value == null);

  Future<Map<String, double>> distances(
      List<CommunityPost> posts, LatLng user) async {
    final result = <String, double>{};
    for (var start = 0; start < posts.length; start += 4) {
      await Future.wait(posts.skip(start).take(4).map((post) async {
        LatLng? point;
        final lat = post.placeLatitude;
        final lng = post.placeLongitude;
        if (lat != null &&
            lng != null &&
            lat.isFinite &&
            lng.isFinite &&
            lat.abs() <= 90 &&
            lng.abs() <= 180) {
          point = LatLng(lat, lng);
        } else {
          final address = (post.placeAddress?.trim().isNotEmpty == true
                  ? post.placeAddress
                  : post.destination)
              ?.trim();
          if (address == null || address.isEmpty) return;
          try {
            point = await _cache.get(address,
                () => _geocode(address).timeout(const Duration(seconds: 10)));
          } catch (_) {
            return;
          }
        }
        if (point == null) return;
        result[post.id] = Geolocator.distanceBetween(
            user.latitude, user.longitude, point.latitude, point.longitude);
      }));
    }
    return result;
  }
}
