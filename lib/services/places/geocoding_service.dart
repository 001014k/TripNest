import '../infrastructure/server_api_client.dart';
import '../infrastructure/async_ttl_cache.dart';
import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class GeocodingService {
  const GeocodingService({http.Client? client}) : _client = client;
  final http.Client? _client;
  static final _coordinates = AsyncTtlCache<String, LatLng?>(
      ttl: const Duration(hours: 24), isEmpty: (value) => value == null);
  static final _addresses = AsyncTtlCache<String, String?>(
      ttl: const Duration(hours: 24), isEmpty: (value) => value == null);

  Future<LatLng?> findCoordinates(String address) {
    final key = address.trim();
    if (key.isEmpty) return Future.value(null);
    return _client == null
        ? _coordinates.get(key, () => _findCoordinates(key))
        : _findCoordinates(key);
  }

  Future<String?> findAddress(double latitude, double longitude) {
    final key = '$latitude,$longitude';
    return _client == null
        ? _addresses.get(key, () => _findAddress(latitude, longitude))
        : _findAddress(latitude, longitude);
  }

  Future<LatLng?> _findCoordinates(String address) async {
    final response = await (_client?.get ?? ServerApiClient().get)(
      Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': address,
        'language': 'ko',
        'region': 'kr',
        'key': 'server-managed',
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('주소 조회 실패 (HTTP ${response.statusCode})');
    }
    final data = jsonDecode(response.body);
    if (data['status'] != 'OK' && data['status'] != 'ZERO_RESULTS') {
      throw StateError('주소 조회 실패: ${data['status']}');
    }
    final results = (data['results'] as List?) ?? const [];
    if (results.isEmpty) return null;
    final location = (results.first as Map)['geometry']?['location'] as Map?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  Future<String?> _findAddress(double latitude, double longitude) async {
    final response = await (_client?.get ?? ServerApiClient().get)(
      Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '$latitude,$longitude',
        'key': 'server-managed',
        'language': 'ko',
      }),
    ).timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) {
      throw StateError('주소 조회 실패 (HTTP ${response.statusCode})');
    }
    final data = jsonDecode(response.body);
    if (data['status'] == 'ZERO_RESULTS') return null;
    if (data['status'] != 'OK') throw StateError('주소 조회 실패: ${data['status']}');
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;
    return results.first['formatted_address'] as String?;
  }
}
