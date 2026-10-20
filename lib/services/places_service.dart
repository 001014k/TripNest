import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../env.dart';

class PlacesService {
  PlacesService({http.Client? client, String? apiKey})
      : _client = client ?? http.Client(),
        apiKey = apiKey ?? Env.googleMapsApiKey;
  final http.Client _client;
  final String apiKey;

  Future<List<String>> searchPhotoUrls(String query) async {
    if (query.isEmpty) return [];
    final response = await _client.post(
      Uri.https('places.googleapis.com', '/v1/places:searchText'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask': 'places.id,places.photos',
      },
      body: jsonEncode({'textQuery': query, 'languageCode': 'ko'}),
    );
    if (response.statusCode != 200) return [];
    final places = jsonDecode(response.body)['places'] as List<dynamic>?;
    if (places == null || places.isEmpty) return [];
    return (places.first['photos'] as List? ?? const [])
        .take(6)
        .map(
            (photo) => 'https://places.googleapis.com/v1/${photo['name']}/media'
                '?key=$apiKey&maxWidthPx=800')
        .toList();
  }

  Future<Map<String, dynamic>?> searchPlaceDetails(String query) async {
    final search = await _client.post(
      Uri.https('places.googleapis.com', '/v1/places:searchText'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.id,places.displayName,places.formattedAddress',
      },
      body: jsonEncode({'textQuery': query, 'languageCode': 'ko'}),
    );
    if (search.statusCode != 200) {
      throw PlacesLookupException(search.statusCode);
    }
    final places = jsonDecode(search.body)['places'] as List<dynamic>?;
    if (places == null || places.isEmpty) return null;
    final placeId = places.first['id'] as String?;
    if (placeId == null) return null;
    final details = await _client.get(
      Uri.https('places.googleapis.com', '/v1/places/$placeId', {
        'fields':
            'currentOpeningHours,regularOpeningHours,rating,userRatingCount,internationalPhoneNumber,nationalPhoneNumber,formattedAddress,googleMapsUri',
        'languageCode': 'ko',
        'key': apiKey,
      }),
    );
    if (details.statusCode != 200) {
      throw PlacesLookupException(details.statusCode);
    }
    return jsonDecode(details.body) as Map<String, dynamic>;
  }

  Future<List<Map<String, dynamic>>> searchPlacesByKeyword(
      String keyword) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': apiKey,
        'X-Goog-FieldMask':
            'places.displayName,places.formattedAddress,places.location,places.photos,places.rating,places.userRatingCount',
      },
      body: jsonEncode({
        'textQuery': keyword,
        'languageCode': 'ko',
        'maxResultCount': 5, // Get up to 5 results for each keyword
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['places'] != null) {
        return List<Map<String, dynamic>>.from(data['places']);
      }
    } else {
      debugPrint('Failed to search for places: ${response.body}');
    }
    return [];
  }
}

class PlacesLookupException implements Exception {
  const PlacesLookupException(this.statusCode);
  final int statusCode;
  @override
  String toString() => '장소 정보 조회 실패 (HTTP $statusCode)';
}
