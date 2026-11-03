import 'shared_link_platform.dart';
import 'social_extraction_service.dart';

class ApifyService {
  ApifyService({SocialExtractionService? extraction})
      : _extraction = extraction ?? SocialExtractionService();
  final SocialExtractionService _extraction;
  Future<List<dynamic>> fetchInstagramData(
      {required String instagramUrl}) async {
    final uri = Uri.tryParse(instagramUrl.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        !SharedLinkPlatform.domain(uri.host.toLowerCase(), 'instagram.com')) {
      throw const FormatException('Apify는 인스타그램 링크에만 사용할 수 있습니다.');
    }
    final rows = await _extraction.fetch('Instagram', instagramUrl);
    validateInstagramResults(rows);
    return rows;
  }

  static void validateInstagramResults(List<dynamic> results) {
    if (results
        .whereType<Map>()
        .any((item) => item['caption']?.toString().trim().isNotEmpty == true)) {
      return;
    }
    for (final item in results.whereType<Map>()) {
      if (item['error'] == 'restricted_page') {
        throw InstagramAccessException(item['restricted_age'] != null
            ? '인스타그램의 연령 제한으로 게시물 본문을 가져오지 못했어요. 지도에서 장소를 검색해 저장해주세요.'
            : '인스타그램의 접근 제한으로 게시물 본문을 가져오지 못했어요. 지도에서 장소를 검색해 저장해주세요.');
      }
    }
  }
}

class InstagramAccessException implements Exception {
  const InstagramAccessException(this.message);
  final String message;
  @override
  String toString() => message;
}
