import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart'; // ← 기존 Place 모델

class BlogParserService {
  Future<Place?> parseNaverBlog(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final document = parse(response.body);

      final title = document.querySelector('meta[property="og:title"]')
          ?.attributes['content']
          ?.trim();

      final address = document.querySelector('.se-address')?.text.trim() ??
          document.querySelector('p')?.text.trim();

      if (title != null && address != null) {
        final coords = await locationFromAddress(address);
        final loc = coords.first;

        return Place(
          id: DateTime.now().millisecondsSinceEpoch.toString(), // 유일 ID
          title: title,
          snippet: address,
          latLng: LatLng(loc.latitude, loc.longitude),
        );
      }
    } catch (e) {
      print('❌ Blog parsing failed: $e');
    }

    return null;
  }
}
