import 'dart:convert';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

import '../env.dart';

class GeocodingService {
  const GeocodingService();

  Future<LatLng?> findCoordinates(String address) async {
    final response = await http.get(
      Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'address': address,
        'language': 'ko',
        'region': 'kr',
        'key': Env.googleMapsApiKey,
      }),
    );
    if (response.statusCode != 200) return null;
    final results = (jsonDecode(response.body)['results'] as List?) ?? const [];
    if (results.isEmpty) return null;
    final location = (results.first as Map)['geometry']?['location'] as Map?;
    final lat = (location?['lat'] as num?)?.toDouble();
    final lng = (location?['lng'] as num?)?.toDouble();
    return lat == null || lng == null ? null : LatLng(lat, lng);
  }

  Future<String?> findAddress(double latitude, double longitude) async {
    final response = await http.get(
      Uri.https('maps.googleapis.com', '/maps/api/geocode/json', {
        'latlng': '$latitude,$longitude',
        'key': Env.googleMapsApiKey,
        'language': 'ko',
      }),
    );
    if (response.statusCode != 200) return null;
    final data = jsonDecode(response.body);
    if (data['status'] != 'OK') return null;
    final results = data['results'] as List?;
    if (results == null || results.isEmpty) return null;
    return results.first['formatted_address'] as String?;
  }
}
