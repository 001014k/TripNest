import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../env.dart';

class AddressToPhotoService {
  static final _instance = AddressToPhotoService._();
  factory AddressToPhotoService() => _instance;
  AddressToPhotoService._();

  /// 주소 → Google에서 검색 → 첫 번째 장소의 사진 URL 반환
  Future<String?> getPhotoUrlFromAddress(String address) async {
    if (address.isEmpty || address.contains('불러올 수 없습니다')) return null;

    final encoded = Uri.encodeComponent(address);
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
          '?query=$encoded'
          '&key=${Env.googleMapsApiKey}'
          '&language=ko',
    );

    try {
      final res = await http.get(url);
      final data = jsonDecode(res.body);

      if (data['status'] == 'OK' && data['results'] != null && data['results'].isNotEmpty) {
        final photos = data['results'][0]['photos'];
        if (photos != null && photos.isNotEmpty) {
          final photoRef = photos[0]['photo_reference'];
          return 'https://maps.googleapis.com/maps/api/place/photo'
              '?maxwidth=400'
              '&photoreference=$photoRef'
              '&key=${Env.googleMapsApiKey}';
        }
      }
    } catch (e) {
      debugPrint('주소 → 사진 변환 실패: $e');
    }

    return null;
  }
}