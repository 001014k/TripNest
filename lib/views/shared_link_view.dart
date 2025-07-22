import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/shared_link_viewmodel.dart';

class LinkPreviewData {
  final String? title;
  final String? description;
  final String? image;

  LinkPreviewData({this.title, this.description, this.image});
}

// URL에서 OpenGraph 메타데이터를 파싱하는 함수 예시
Future<LinkPreviewData> getPreviewData(String url) async {
  final response = await http.get(Uri.parse(url));
  if (response.statusCode != 200) {
    throw Exception('Failed to load preview data');
  }
  final document = html_parser.parse(response.body);

  String? extractMetaContent(String property) {
    return document
        .querySelector('meta[property="$property"]')
        ?.attributes['content'];
  }

  final title = extractMetaContent('og:title') ??
      document.querySelector('title')?.text;
  final description = extractMetaContent('og:description');
  final image = extractMetaContent('og:image');

  return LinkPreviewData(title: title, description: description, image: image);
}

class SharedLinkView extends StatefulWidget {
  const SharedLinkView({Key? key}) : super(key: key);

  @override
  State<SharedLinkView> createState() => _SharedLinkViewState();
}

class _SharedLinkViewState extends State<SharedLinkView> {
  late SharedLinkViewModel _viewModel;
  StreamSubscription<List<SharedMediaFile>>? _intentStreamSub;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SharedLinkViewModel>();

    _intentStreamSub = ReceiveSharingIntent.instance.getMediaStream().listen(
          (List<SharedMediaFile> sharedFiles) {
        for (final file in sharedFiles) {
          if (file.type == "text/plain") {
            final urls = _extractUrls(file.path);
            for (var url in urls) {
              _viewModel.saveLink(url);
            }
          }
        }
      },
      onError: (err) {
        print('공유 데이터 수신 오류: $err');
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then(
          (List<SharedMediaFile> sharedFiles) {
        for (final file in sharedFiles) {
          if (file.type == "text/plain") {
            final urls = _extractUrls(file.path);
            for (var url in urls) {
              _viewModel.saveLink(url);
            }
          }
        }
      },
    );

    _viewModel.loadSharedLinks();
  }

  @override
  void dispose() {
    _intentStreamSub?.cancel();
    super.dispose();
  }

  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SharedLinkViewModel>(
      builder: (context, vm, child) {
        if (vm.errorMessage != null) {
          return Center(child: Text(vm.errorMessage!));
        }
        if (vm.sharedLinks.isEmpty) {
          return const Center(child: Text('공유된 링크가 없습니다.'));
        }

        return ListView.builder(
          itemCount: vm.sharedLinks.length,
          itemBuilder: (context, index) {
            final link = vm.sharedLinks[index];

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              child: _CustomLinkPreview(
              url: link.url,
              onDelete: () {
                final id = link.id;
                if (id != null) {
                  vm.deleteLink(id);
                } else {
                  print('삭제할 ID가 없습니다.');
                }
              },
            ),
            );
          },
        );
      },
    );
  }
}

class _CustomLinkPreview extends StatefulWidget {
  final String url;
  final VoidCallback onDelete;

  const _CustomLinkPreview({
    required this.url,
    required this.onDelete,
    Key? key,
  }) : super(key: key);

  @override
  State<_CustomLinkPreview> createState() => _CustomLinkPreviewState();
}

class _CustomLinkPreviewState extends State<_CustomLinkPreview> {
  LinkPreviewData? _previewData;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    try {
      final data = await getPreviewData(widget.url);
      setState(() {
        _previewData = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return ListTile(
        title: Text(widget.url),
        subtitle: Text('미리보기 로드 실패: $_error'),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: widget.onDelete,
        ),
      );
    }

    return InkWell(
      onTap: () async {
        final uri = Uri.tryParse(widget.url);
        if (uri != null && await canLaunchUrl(uri)) {
          await launchUrl(uri);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            if (_previewData?.image != null && _previewData!.image!.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  _previewData!.image!,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 100,
                height: 100,
                color: Colors.grey[300],
                child: const Icon(Icons.image, size: 40, color: Colors.white),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _previewData?.title ?? widget.url,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _previewData?.description ?? '',
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: widget.onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

