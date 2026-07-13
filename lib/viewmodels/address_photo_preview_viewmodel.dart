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

  // 완전히 안전한 캐시 키 생성 (공백·대소문자·줄바꿈 무시)
  String get _cacheKey {
    final addr = address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final ttl = title?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_') ?? 'no_title';
    return '$addr|$ttl';
  }

  Future<void> _loadPhotoUrl() async {
    _isLoading = true;
    notifyListeners();

    debugPrint('🔍 AddressPhotoPreviewViewModel 시작');
    debugPrint('   주소: "$address"');
    debugPrint('   제목: "$title"');
    debugPrint('   캐시 키: "$_cacheKey"');

    try {
      final box = Hive.box<CachedPhotoUrl>('photo_urls');
      debugPrint('   저장된 키들: ${box.keys.toList()}');

      final cached = box.get(_cacheKey);
      if (cached != null && cached.isValid) {
        _photoUrl = cached.photoUrl;
        _isLoading = false;
        notifyListeners();
        debugPrint('✅ 캐시 히트 성공! $_photoUrl');
        return;
      }
      debugPrint('⚠️ 캐시 미스 또는 만료, API 호출 시작');

      // API 호출
      String query = address;
      if (title != null && title!.isNotEmpty) query = '$title $address';

      debugPrint('   API Query: "$query"'); // Query 로깅

      final uri = Uri.https('places.googleapis.com', '/v1/places:searchText');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          'X-Goog-FieldMask': 'places.photos,places.displayName,places.id',
        },
        body: jsonEncode({"textQuery": query}),
      );

      debugPrint('   API Response Status: ${response.statusCode}'); // Status Code 로깅
      debugPrint('   API Response Body: ${response.body}'); // Body 로깅

      if (response.statusCode != 200) throw Exception('HTTP ${response.statusCode}');

      final data = jsonDecode(response.body);
      final photos = (data['places'] as List?)?.first['photos'] as List<dynamic>? ?? [];

      if (photos.isEmpty) throw Exception('사진 없음');

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

      debugPrint('✅ API 성공 & 캐시 저장 완료: $_photoUrl');
    } catch (e, s) {
      debugPrint('❌ 오류 발생: $e\n$s');
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 강제 새로고침 (필요시 사용)
  Future<void> refresh() async {
    final box = Hive.box<CachedPhotoUrl>('photo_urls');
    await box.delete(_cacheKey);
    _loadPhotoUrl();
  }
}