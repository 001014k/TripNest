import 'package:http/http.dart' as http;
import 'package:html/parser.dart';
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/place_model.dart';

class InstagramParserService {
  Future<Place?> parseInstagram(String url) async {
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) return null;

      final document = parse(response.body);

      final title = document.querySelector('meta[property="og:title"]')
          ?.attributes['content']
          ?.trim();

      final address = _extractAddress(document.outerHtml);

      if (title != null && address != null) {
        final coords = await locationFromAddress(address);
        final loc = coords.first;

        return Place(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: title,
          snippet: address,
          latLng: LatLng(loc.latitude, loc.longitude),
        );
      }
    } catch (e) {
      print('❌ Instagram parsing failed: $e');
    }

    return null;
  }

  /// 주소 추출은 HTML 내 정규식/키워드 기반 추정
  String? _extractAddress(String html) {
    final patterns = [
      RegExp(r'서울.*?구.*?(동)?\s?\d+(-\d+)?'),
      RegExp(r'제주.*?읍.*?리.*?\d+'),
      RegExp(r'대한민국.*?'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(html);
      if (match != null) return match.group(0);
    }

    return null;
  }
}
