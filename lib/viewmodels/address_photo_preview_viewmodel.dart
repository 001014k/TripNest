import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../env.dart';
import '../../models/cached_photo_url.dart';

class AddressPhotoPreviewViewModel extends ChangeNotifier {
  final String address;
  final String? title;

  String? _photoUrl;
  bool _isLoading = true;
  String? _error;

  String? get photoUrl => _photoUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AddressPhotoPreviewViewModel(this.address, this.title) {
    _loadPhotoUrl();
  }

  // 완전히 안전한 캐시 키 생성
  String get _cacheKey {
    final addr = address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final ttl = title?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_') ??
        'no_title';
    return '$addr|$ttl';
  }

  Future<void> _loadPhotoUrl() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final box = Hive.box<CachedPhotoUrl>('photo_urls');

      final cached = box.get(_cacheKey);
      if (cached != null && cached.isValid) {
        _photoUrl = cached.photoUrl;
        _isLoading = false;
        notifyListeners();
        return;
      }

      // API Query 개선
      String query = address;
      if (title != null && title!.isNotEmpty) {
        query = '$title, $address';
      }

      final uri = Uri.https('places.googleapis.com', '/v1/places:searchText');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          'X-Goog-FieldMask':
              'places.photos,places.displayName,places.id,places.formattedAddress',
        },
        body: jsonEncode({
          "textQuery": query,
          "maxResultCount": 5,
          "languageCode": "ko",
          "regionCode": "KR",
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('HTTP ${response.statusCode}');
      }

      final data = jsonDecode(response.body);
      final places = data['places'] as List? ?? [];

      if (places.isEmpty) {
        _error = '장소 사진이 없습니다.';
        return;
      }

      // 가장 잘 맞는 장소 선택
      Map<String, dynamic>? bestPlace;
      double bestScore = -1.0;

      for (final place in places) {
        final displayName =
            (place['displayName']?['text'] as String?)?.toLowerCase() ?? '';
        final formattedAddr =
            (place['formattedAddress'] as String?)?.toLowerCase() ?? '';

        double score = 0.0;

        // 제목 매칭
        if (title != null &&
            title!.isNotEmpty &&
            displayName.contains(title!.toLowerCase())) {
          score += 0.6;
        }
        // 주소 매칭 (단어 단위)
        if (address.isNotEmpty) {
          final addressWords = address.toLowerCase().split(RegExp(r'\s+'));
          final matchCount =
              addressWords.where((word) => formattedAddr.contains(word)).length;
          score += (matchCount / addressWords.length) * 0.4;
        }

        if (score > bestScore) {
          bestScore = score;
          bestPlace = place;
        }
      }

      // fallback
      bestPlace ??= places.first;

      final photos = (bestPlace?['photos'] as List<dynamic>?) ?? [];
      if (photos.isEmpty) {
        _error = '장소 사진이 없습니다.';
        return;
      }

      final photoName = photos[0]['name'] as String;
      _photoUrl = 'https://places.googleapis.com/v1/$photoName/media'
          '?key=${Env.googleMapsApiKey}&maxWidthPx=600';

      // 캐시 저장
      await box.put(
        _cacheKey,
        CachedPhotoUrl(
          cacheKey: _cacheKey,
          photoUrl: _photoUrl!,
        ),
      );
    } catch (e) {
      debugPrint('장소 사진 미리보기를 불러오지 못했습니다: $e');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 강제 새로고침
  Future<void> refresh() async {
    final box = Hive.box<CachedPhotoUrl>('photo_urls');
    await box.delete(_cacheKey);
    _loadPhotoUrl();
  }
}
