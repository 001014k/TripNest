import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../env.dart';
import '../../models/shared_links/link_place_preview_model.dart';
import '../ai/gemini_service.dart';
import 'link_place_extractor_service.dart';
import 'shared_link_platform.dart';

/// Public post text only; never includes other users' replies or quoted posts.
class ThreadsPlaceExtractorService {
  ThreadsPlaceExtractorService({http.Client? client, String? token})
      : _client = client,
        _token = token;
  final http.Client? _client;
  final String? _token;

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

  /// Resolve app share links before invoking the paid actor. Never send API
  /// credentials to Threads, and never follow redirects outside Threads.
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
    final token = _token ?? Env.apifyApiToken;
    if (token.isEmpty) throw const FormatException('Apify API 키가 설정되지 않았습니다.');
    final client = _client ?? http.Client();
    try {
      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      };
      final run = await client
          .post(
            Uri.https('api.apify.com', '/v2/acts/memo23~threads-scraper/runs',
                {'timeout': '120'}),
            headers: headers,
            body: jsonEncode({
              'postUrls': [uri.toString()],
              'includeReplies': true,
              'maxItems': 100
            }),
          )
          .timeout(const Duration(seconds: 20));
      final data = _decode(run)['data'] as Map;
      final id = data['id'];
      final dataset = data['defaultDatasetId'];
      if (id == null || dataset == null) {
        throw const FormatException('Threads 수집 실행 정보를 가져오지 못했습니다.');
      }
      for (var attempt = 0; attempt < 65; attempt++) {
        final response = await client
            .get(Uri.https('api.apify.com', '/v2/actor-runs/$id'),
                headers: headers)
            .timeout(const Duration(seconds: 15));
        final status = _decode(response)['data']['status'];
        if (status == 'SUCCEEDED') {
          final response = await client
              .get(
                  Uri.https('api.apify.com', '/v2/datasets/$dataset/items',
                      {'clean': 'true', 'limit': '100'}),
                  headers: headers)
              .timeout(const Duration(seconds: 20));
          final rows = _decode(response);
          if (rows is! List) {
            throw const FormatException('Threads 수집 결과 형식이 올바르지 않습니다.');
          }
          return rows;
        }
        if (['FAILED', 'ABORTED', 'TIMED-OUT'].contains(status)) {
          throw const FormatException(
              'Threads 글을 가져오지 못했습니다. 공개 게시물인지 확인하고 다시 시도해주세요.');
        }
        await Future<void>.delayed(const Duration(seconds: 2));
      }
      throw TimeoutException('Threads 분석 시간이 초과되었습니다. 다시 시도해주세요.');
    } finally {
      if (_client == null) client.close();
    }
  }

  dynamic _decode(http.Response response) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FormatException(
          'Threads 수집 서비스 요청에 실패했습니다 (${response.statusCode}). 잠시 후 다시 시도해주세요.');
    }
    return jsonDecode(utf8.decode(response.bodyBytes));
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
