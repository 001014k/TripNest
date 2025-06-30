import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:convert';
import 'package:http/http.dart' as http;

// SearchService: Google Places API와 지오코딩 검색
class SearchService {
  final String apiKey;

  SearchService({required this.apiKey});

  /// Google Places API 검색
  Future<List<Marker>> searchPlacesWithQuery(String query) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText?&key=$apiKey');

    final requestBody = json.encode({
      "textQuery": query,
      "languageCode": "ko",
    });

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-FieldMask': 'places.displayName,places.formattedAddress,places.location'
      },
      body: requestBody,
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['places'] != null && data['places'] is List) {
        return (data['places'] as List).map<Marker>((place) {
          final displayName = place['displayName']['text'];
          final formattedAddress = place['formattedAddress'];
          final lat = place['location']['latitude'];
          final lng = place['location']['longitude'];
          final placeId = place['place_id'] ?? displayName;

          return Marker(
            markerId: MarkerId(placeId),
            position: LatLng(lat, lng),
            infoWindow: InfoWindow(
              title: displayName,
              snippet: formattedAddress,
            ),
          );
        }).toList();
      }
    }
    return [];
  }

  /// 지오코딩을 이용한 검색
  Future<Marker?> geocodeSearch(String query) async {
    try {
      final locations = await geocoding.locationFromAddress(query);
      if (locations.isNotEmpty) {
        final location = locations.first;
        return Marker(
          markerId: MarkerId('searchLocation'),
          position: LatLng(location.latitude, location.longitude),
          infoWindow: InfoWindow(title: query),
        );
      }
    } catch (_) {}
    return null;
  }
}
