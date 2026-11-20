import '../infrastructure/server_api_client.dart';
import 'place_lookup_repository.dart';
export 'place_lookup_repository.dart' show PlacesLookupException;
import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class PlacesService {
  PlacesService(
      {http.Client? client, String? apiKey, PlaceLookupRepository? repository})
      : _client = client ?? ServerApiClient(),
        apiKey = apiKey ?? 'server-managed',
        _repository = repository ??
            (client == null && apiKey == null
                ? PlaceLookupRepository.shared
                : PlaceLookupRepository(
                    client: client, apiKey: apiKey ?? 'server-managed'));
  final http.Client _client;
  final String apiKey;
  final PlaceLookupRepository _repository;
  Future<Map<String, dynamic>?> searchPlaceDetails(String query) =>
      _repository.lookup(query, PlaceLookupRepository.detailFields);

  Future<Map<String, dynamic>?> searchRating(String query) =>
      _repository.lookup(query, 'id,rating,userRatingCount');

  Future<List<String>> searchPhotoUrls(String query) async =>
      PlaceLookupRepository.photoUrls(
          await _repository.lookup(query, PlaceLookupRepository.photoFields));

  Future<List<Map<String, dynamic>>> searchPlacesByKeyword(
      String keyword) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    final response = await _client
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': apiKey,
            'X-Goog-FieldMask':
                'places.id,places.displayName,places.formattedAddress,places.location,places.rating,places.userRatingCount',
          },
          body: jsonEncode({
            'textQuery': keyword,
            'languageCode': 'ko',
            'maxResultCount': 5, // 키워드별로 최대 5개 결과를 가져옵니다.
          }),
        )
        .timeout(const Duration(seconds: 15));

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
