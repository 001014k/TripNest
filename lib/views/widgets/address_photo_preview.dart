import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../design/app_design.dart';
import '../../env.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddressPhotoPreview extends StatelessWidget {
  final String address;
  final String? title;
  final double size;
  final Widget? child;

  const AddressPhotoPreview({
    required this.address,
    required this.title,
    required this.size,
    this.child,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getPhotoUrl(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data != null) {
          return Stack(
            children: [
              CachedNetworkImage(
                imageUrl: snapshot.data!,
                width: double.infinity,
                height: size,
                fit: BoxFit.cover,
                placeholder: (_, __) => _gradientPlaceholder(),
                errorWidget: (_, __, ___) => _gradientPlaceholder(),
              ),
              if (child != null) child!, // 오버레이
            ],
          );
        }
        return _gradientPlaceholder();
      },
    );
  }

  Widget _gradientPlaceholder() {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,  // ← 당신 기존 그라데이션 그대로!
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      ),
      child: const Center(
        child: Icon(Icons.place, color: Colors.white, size: 40),
      ),
    );
  }

  // lib/widgets/address_photo_preview.dart 안의 _getPhotoUrl() 함수만 통째로 교체!

  Future<String?> _getPhotoUrl() async {
    String query = address;

    if (title != null && title!.isNotEmpty) {
      query = '$title $address';
    }

    if (address.isEmpty || address.contains('불러올 수 없습니다')) {
      debugPrint('주소 없음 → placeholder');
      return null;
    }

    final url = Uri.https('places.googleapis.com', '/v1/places:searchText');

    final body = {
      "textQuery": query   // ← 여기만 바꾸면 됨!
    };

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': Env.googleMapsApiKey,
          // 이 필드가 사진을 가져오게 해줍니다 (필수!)
          'X-Goog-FieldMask': 'places.id,places.displayName,places.photos',
        },
        body: jsonEncode(body),
      );

      debugPrint('Places API (New) 상태코드: ${response.statusCode}');
      debugPrint('응답 본문: ${response.body}');

      if (response.statusCode != 200) {
        debugPrint('HTTP 오류: ${response.statusCode}');
        return null;
      }

      final data = jsonDecode(response.body);

      if (data['places'] == null || data['places'].isEmpty) {
        debugPrint('검색 결과 없음');
        return null;
      }

      final photos = data['places'][0]['photos'];
      if (photos == null || photos.isEmpty) {
        debugPrint('이 장소에는 사진이 없음');
        return null;
      }

      // 첫 번째 사진으로 URL 생성 (신규 방식)
      final photoName = photos[0]['name'];  // "places/ChIJ.../photos/..."
      final photoUrl = 'https://places.googleapis.com/v1/$photoName/media'
          '?key=${Env.googleMapsApiKey}'
          '&maxWidthPx=600';

      debugPrint('성공! 신규 사진 URL: $photoUrl');
      return photoUrl;

    } catch (e, s) {
      debugPrint('Places API (New) 예외: $e\n$s');
      return null;
    }
  }
}