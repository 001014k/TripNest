import 'dart:convert';
import 'package:html/parser.dart' as html;
import 'package:http/http.dart' as http;
import '../models/instagram_place_source_model.dart';
import '../models/link_place_preview_model.dart';
import 'gemini_service.dart';
import 'link_place_extractor_service.dart';
import 'shared_link_platform.dart';

/// Reads public review articles. Does not bypass login or bot protection.
class PortalPlaceExtractorService {
  PortalPlaceExtractorService(
      {http.Client? client,
      Future<List<InstagramPlaceSource>> Function(String)? extractSources,
      Future<List<LinkPlacePreview>> Function(String)? search})
      : _client = client,
        _extractSources = extractSources ??
            ((text) => GeminiService().extractPlacesFromText(text)),
        _search = search ?? const LinkPlaceExtractorService().search;
  final http.Client? _client;
  final Future<List<InstagramPlaceSource>> Function(String) _extractSources;
  final Future<List<LinkPlacePreview>> Function(String) _search;

  Future<List<LinkPlacePreview>> extract(String url,
      {String? sharedText}) async {
    if (!SharedLinkPlatform.supportsPlaces(url)) {
      throw const FormatException('지원하지 않는 링크입니다.');
    }
    final client = _client ?? http.Client();
    try {
      var uri = Uri.parse(url);
      var content = '';
      final seen = <String>{};
      for (var step = 0; step < 7; step++) {
        if (!['http', 'https'].contains(uri.scheme) ||
            !SharedLinkPlatform.supportsPlaces(uri.toString()) ||
            uri.userInfo.isNotEmpty ||
            (uri.hasPort && uri.port != 80 && uri.port != 443)) {
          throw const FormatException('지원하는 공개 링크로 공유해주세요.');
        }
        if (!seen.add(uri.toString())) {
          throw const FormatException('공유 링크의 이동 경로를 확인할 수 없습니다.');
        }
        // Desktop Naver blogs commonly serve an iframe shell instead of the post.
        if (uri.host == 'blog.naver.com') {
          uri = uri.replace(host: 'm.blog.naver.com');
        }
        final request = http.Request('GET', uri)..followRedirects = false;
        request.headers.addAll(
            {'User-Agent': 'Mozilla/5.0', 'Accept-Language': 'ko-KR,ko;q=0.9'});
        final response =
            await client.send(request).timeout(const Duration(seconds: 10));
        if ([301, 302, 303, 307, 308].contains(response.statusCode)) {
          await response.stream
              .drain<void>()
              .timeout(const Duration(seconds: 10));
          final next = response.headers['location'];
          if (next == null) throw const FormatException('원본 링크를 찾을 수 없습니다.');
          uri = uri.resolve(next);
          continue;
        }
        if (response.statusCode != 200) {
          await response.stream
              .drain<void>()
              .timeout(const Duration(seconds: 10));
          if (sharedText == null || sharedText.trim().isEmpty) {
            throw const FormatException(
                '페이지를 읽을 수 없습니다. 장소명과 주소가 포함된 공유 텍스트도 함께 보내주세요.');
          }
          break;
        }
        final bytes = <int>[];
        await for (final chunk
            in response.stream.timeout(const Duration(seconds: 10))) {
          bytes.addAll(chunk);
          if (bytes.length > 2000000) {
            throw const FormatException('페이지가 너무 큽니다. 장소 상세 링크를 공유해주세요.');
          }
        }
        final doc = html.parse(utf8.decode(bytes, allowMalformed: true));
        // Public cafe desktop pages may wrap the article in a same-provider frame.
        final frame = doc.querySelector(
            'iframe#cafe_main, iframe[name="cafe_main"], iframe#down');
        final frameSource = frame?.attributes['src'];
        if (frameSource != null && frameSource.isNotEmpty) {
          final target = uri.resolve(frameSource);
          if (SharedLinkPlatform.supportsPlaces(target.toString())) {
            uri = target;
            continue;
          }
        }
        final metadata = doc
            .querySelectorAll(
                'meta[property="og:title"],meta[property="og:description"],meta[name="description"]')
            .map((e) => e.attributes['content'] ?? '')
            .join('\n');
        final structured = doc
            .querySelectorAll('script[type="application/ld+json"]')
            .map((e) => e.text)
            .join('\n');
        for (final e
            in doc.querySelectorAll('script,style,nav,footer,header')) {
          e.remove();
        }
        final body = doc.querySelector('.se-main-container') ??
            doc.querySelector('#postViewArea') ??
            doc.querySelector('.article_view') ??
            doc.querySelector('.tt_article_useless_p_margin') ??
            doc.querySelector('#user_contents') ??
            doc.querySelector('.post-body') ??
            doc.querySelector('article') ??
            doc.querySelector('main') ??
            doc.body;
        content =
            '${doc.querySelector('title')?.text ?? ''}\n$metadata\n$structured\n${body?.text ?? ''}';
        content = content.replaceAll(RegExp(r'\s+'), ' ').trim();
        break;
      }
      final text = [content, sharedText ?? ''].join('\n').trim();
      if (text.isEmpty) {
        throw const FormatException('공유 링크에서 공개된 장소 정보를 읽지 못했습니다.');
      }
      final bounded = text.length > 18000 ? text.substring(0, 18000) : text;
      final sources = await _extractSources(bounded);
      final results = <String, LinkPlacePreview>{};
      for (final source in sources.take(15)) {
        // Never save an AI-invented name not present in the source.
        if (!_normalize(bounded).contains(_normalize(source.name)) ||
            source.name.trim().isEmpty) {
          continue;
        }
        final query = [
          source.name,
          if (source.address?.trim().isNotEmpty ?? false) source.address!
        ].join(' ');
        final matches = await _search(query);
        final address = source.address?.trim();
        if (address != null &&
            address.isNotEmpty &&
            !_normalize(bounded).contains(_normalize(address))) {
          continue;
        }
        final verified =
            matches.where((p) => _matches(p, source.name, address));
        if (verified.isEmpty) continue;
        final p = verified.first;
        results.putIfAbsent(
            '${p.title}|${p.address}',
            () => LinkPlacePreview(
                url: url,
                title: p.title,
                address: p.address,
                latitude: p.latitude,
                longitude: p.longitude));
      }
      if (results.isEmpty) {
        throw const FormatException(
            '확인 가능한 장소를 찾지 못했습니다. 장소명과 주소가 보이는 공개 링크를 공유해주세요.');
      }
      return results.values.toList();
    } finally {
      if (_client == null) client.close();
    }
  }

  bool _matches(LinkPlacePreview p, String name, String? address) {
    if (p.title.trim().isEmpty ||
        p.address.trim().isEmpty ||
        p.latitude == null ||
        p.longitude == null) {
      return false;
    }
    final sourceName = _normalize(name);
    final resultName = _normalize(p.title);
    if (sourceName.isEmpty ||
        !(resultName.contains(sourceName) || sourceName.contains(resultName))) {
      return false;
    }
    if (address == null || address.isEmpty) return true;
    final target = _normalize(p.address);
    final districts =
        RegExp(r'[가-힣]+(?:구|군)').allMatches(address).map((m) => m.group(0)!);
    if (districts.any((district) => !target.contains(district))) return false;
    final road =
        RegExp(r'([가-힣0-9]+(?:로|길))\s*(\d+(?:-\d+)?)').firstMatch(address);
    if (road != null && !target.contains(_normalize(road.group(0)!))) {
      return false;
    }
    return true;
  }

  String _normalize(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^가-힣a-z0-9]'), '');
}
