import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../env.dart';
import '../models/cached_photo_url.dart';

class AddressPhotoPreviewService {
  const AddressPhotoPreviewService();

  String cacheKey(String address, String? title) {
    final addr = address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final ttl = title?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_') ??
        'no_title';
    return '$addr|$ttl';
  }

  Future<String?> load(String address, String? title) async {
    final key = cacheKey(address, title);
    final box = Hive.box<CachedPhotoUrl>('photo_urls');
    final cached = box.get(key);
    if (cached != null && cached.isValid) return cached.photoUrl;

    final query =
        title != null && title.isNotEmpty ? '$title, $address' : address;
    final response = await http.post(
      Uri.https('places.googleapis.com', '/v1/places:searchText'),
      headers: {
        'Content-Type': 'application/json',
        'X-Goog-Api-Key': Env.googleMapsApiKey,
        'X-Goog-FieldMask':
            'places.photos,places.displayName,places.id,places.formattedAddress',
      },
      body: jsonEncode({
        'textQuery': query,
        'maxResultCount': 5,
        'languageCode': 'ko',
        'regionCode': 'KR',
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('HTTP ${response.statusCode}');
    }

    final places = (jsonDecode(response.body)['places'] as List?) ?? [];
    if (places.isEmpty) return null;

    Map<String, dynamic>? bestPlace;
    var bestScore = -1.0;
    for (final rawPlace in places) {
      final place = rawPlace as Map<String, dynamic>;
      final displayName =
          (place['displayName']?['text'] as String?)?.toLowerCase() ?? '';
      final formattedAddress =
          (place['formattedAddress'] as String?)?.toLowerCase() ?? '';
      var score = 0.0;
      if (title != null &&
          title.isNotEmpty &&
          displayName.contains(title.toLowerCase())) {
        score += 0.6;
      }
      if (address.isNotEmpty) {
        final words = address.toLowerCase().split(RegExp(r'\s+'));
        final matches =
            words.where((word) => formattedAddress.contains(word)).length;
        score += (matches / words.length) * 0.4;
      }
      if (score > bestScore) {
        bestScore = score;
        bestPlace = place;
      }
    }

    final photos = (bestPlace?['photos'] as List<dynamic>?) ?? [];
    if (photos.isEmpty) return null;
    final photoName = photos.first['name'] as String;
    final photoUrl = 'https://places.googleapis.com/v1/$photoName/media'
        '?key=${Env.googleMapsApiKey}&maxWidthPx=600';
    await box.put(key, CachedPhotoUrl(cacheKey: key, photoUrl: photoUrl));
    return photoUrl;
  }

  Future<void> clear(String address, String? title) async {
    await Hive.box<CachedPhotoUrl>('photo_urls')
        .delete(cacheKey(address, title));
  }
}
