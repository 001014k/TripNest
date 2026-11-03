import '../infrastructure/server_api_client.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'dart:convert';

// SearchService: Google Places API와 지오코딩 검색
class SearchService {
  final String apiKey;

  SearchService({this.apiKey = 'server-managed'});

  /// Google Places API 검색
  Future<List<Marker>> searchPlacesWithQuery(String query) async {
    final url = Uri.parse(
        'https://places.googleapis.com/v1/places:searchText?&key=$apiKey');

    final requestBody = json.encode({
      "textQuery": query,
      "languageCode": "ko",
    });

    final response = await ServerApiClient()
        .post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-FieldMask':
                'places.displayName,places.formattedAddress,places.location'
          },
          body: requestBody,
        )
        .timeout(const Duration(seconds: 15));

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
      final locations = await geocoding.Geocoding()
          .locationFromAddress(query)
          .timeout(const Duration(seconds: 15));
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
