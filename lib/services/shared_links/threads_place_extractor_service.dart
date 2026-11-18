import 'dart:async';
import 'package:http/http.dart' as http;
import 'social_extraction_service.dart';
import '../../models/shared_links/link_place_preview_model.dart';
import '../ai/gemini_service.dart';
import 'link_place_extractor_service.dart';
import 'shared_link_platform.dart';

/// 공개 게시물 본문만 사용하며 다른 사용자의 답글이나 인용 게시물은 포함하지 않습니다.
class ThreadsPlaceExtractorService {
  ThreadsPlaceExtractorService(
      {http.Client? client, SocialExtractionService? extraction})
      : _client = client,
        _extraction = extraction ?? SocialExtractionService();
  final http.Client? _client;
  final SocialExtractionService _extraction;

  static Uri postUri(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.userInfo.isNotEmpty ||
        SharedLinkPlatform.detect(url) != 'Threads' ||
        !RegExp(r'^/@[^/]+/post/[^/]+/?$').hasMatch(uri.path)) {
      throw const FormatException('Threads 게시물의 전체 링크를 입력해주세요.');
    }
    return Uri.https(
        'www.threads.com', uri.path.replaceFirst(RegExp(r'/$'), ''));
  }

  /// 유료 작업 실행 전에 앱 공유 링크의 실제 주소를 확인합니다.
  /// Threads에 API 인증 정보를 보내거나 Threads 외부로 리디렉션하지 않습니다.
  Future<Uri> resolvePostUri(String url) async {
    var uri = Uri.tryParse(url.trim());
    final client = _client ?? http.Client();
    try {
      for (var hop = 0; hop < 5; hop++) {
        if (uri == null ||
            !['http', 'https'].contains(uri.scheme) ||
            uri.userInfo.isNotEmpty ||
            uri.hasPort ||
            ![
              'threads.com',
              'www.threads.com',
              'threads.net',
              'www.threads.net'
            ].contains(uri.host.toLowerCase())) {
          throw const FormatException('유효한 Threads 공유 링크가 아닙니다.');
        }
        if (RegExp(r'^/@[^/]+/post/[^/]+/?$').hasMatch(uri.path)) {
          return postUri(uri.toString());
        }
        if (!RegExp(r'^/share/[^/]+/?$').hasMatch(uri.path)) {
          throw const FormatException('Threads 게시물의 전체 링크를 입력해주세요.');
        }
        final request = http.Request('HEAD', uri)..followRedirects = false;
        final response =
            await client.send(request).timeout(const Duration(seconds: 15));
        await response.stream.drain<void>();
        final location = response.headers['location'];
        if (![301, 302, 303, 307, 308].contains(response.statusCode) ||
            location == null) {
          throw const FormatException(
              'Threads 공유 링크를 열지 못했습니다. 게시물이 공개 상태인지 확인해주세요.');
        }
        uri = uri.resolve(location);
      }
      throw const FormatException(
          'Threads 공유 링크의 이동이 너무 많습니다. 게시물 링크를 다시 공유해주세요.');
    } finally {
      if (_client == null) client.close();
    }
  }

  Future<List<dynamic>> fetch(String url) async {
    final uri = await resolvePostUri(url);
    return _extraction.fetch('Threads', uri.toString());
  }

  static String authorText(String url, List<dynamic> rows) {
    final uri = postUri(url);
    final code = uri.pathSegments.last;
    final posts = rows.whereType<Map>().toList();
    final roots = posts.where((row) =>
        row['code'] == code ||
        Uri.tryParse(row['url']?.toString() ?? '')
                ?.pathSegments
                .where((s) => s.isNotEmpty)
                .lastOrNull ==
            code);
    if (roots.isEmpty) {
      throw const FormatException('Threads 원문을 읽지 못했습니다. 공개 게시물인지 확인해주세요.');
    }
    final root = roots.first;
    final author =
        root['username']?.toString().replaceFirst('@', '').toLowerCase();
    final texts = <String>{};
    void add(Map row) {
      final text = row['text']?.toString().trim() ?? '';
      if (text.isNotEmpty) texts.add(text);
    }

    add(root);
    if (author != null && author.isNotEmpty) {
      for (final row in posts) {
        if (row['isReply'] == true &&
            row['username']?.toString().replaceFirst('@', '').toLowerCase() ==
                author &&
            row['replyToAuthor']
                    ?.toString()
                    .replaceFirst('@', '')
                    .toLowerCase() ==
                author) {
          add(row);
        }
      }
    }
    if (texts.isEmpty) {
      throw const FormatException(
          'Threads 글에 분석할 본문이 없습니다. 사진·영상 속 글자는 아직 추출할 수 없어요.');
    }
    return texts.join('\n\n');
  }

  Future<List<LinkPlacePreview>> extract(String url) async {
    final resolved = (await resolvePostUri(url)).toString();
    final text = authorText(resolved, await fetch(resolved));
    final sources = await GeminiService().extractPlacesFromText(text);
    final places = <String, LinkPlacePreview>{};
    for (final source in sources) {
      final matches = await const LinkPlaceExtractorService().search([
        source.name,
        if (source.address?.isNotEmpty == true) source.address!
      ].join(' '));
      if (matches.isEmpty) continue;
      final best = matches.first;
      places['${best.title}|${best.address}'] = LinkPlacePreview(
          url: url,
          title: best.title,
          address: best.address,
          latitude: best.latitude,
          longitude: best.longitude);
    }
    return places.values.toList();
  }
}
