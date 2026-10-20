import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

import '../models/link_preview_data.dart';

class LinkPreviewService {
  const LinkPreviewService({http.Client? client}) : _client = client;

  final http.Client? _client;

  Future<LinkPreviewData> load(String url) async {
    final originalUri = Uri.parse(url);
    // Desktop Naver blogs expose a frame shell, not the post metadata.
    final sourceUri = originalUri.host.toLowerCase() == 'blog.naver.com'
        ? originalUri.replace(host: 'm.blog.naver.com')
        : originalUri;
    final response = await (_client?.get ?? http.get)(
      sourceUri,
      headers: const {
        'User-Agent': 'Mozilla/5.0 (compatible; TripNest/1.0)',
      },
    ).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw Exception('Failed to load preview data');
    }
    final document = html_parser.parse(response.body);

    String? extractMetaContent(String name) {
      return document
              .querySelector('meta[property="$name"]')
              ?.attributes['content'] ??
          document.querySelector('meta[name="$name"]')?.attributes['content'];
    }

    final title =
        extractMetaContent('og:title') ?? document.querySelector('title')?.text;
    final description = extractMetaContent('og:description');
    final image = extractMetaContent('og:image');

    return LinkPreviewData(
      title: title?.trim(),
      description: description?.trim(),
      image: image == null || image.trim().isEmpty
          ? null
          : sourceUri.resolve(image.trim()).toString(),
    );
  }
}
