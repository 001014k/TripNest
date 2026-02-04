import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../env.dart';

class PlacesService {
  final String apiKey = Env.googleMapsApiKey;

  Future<List<Map<String, dynamic>>> searchPlacesByKeyword(String keyword) async {
    final url = Uri.parse('https://places.googleapis.com/v1/places:searchText');

    final response = await http.post(
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
      print('Failed to search for places: ${response.body}');
    }
    return [];
  }
}
