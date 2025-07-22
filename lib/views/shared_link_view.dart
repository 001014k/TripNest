import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/shared_link_viewmodel.dart';

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

    // 미디어(텍스트 포함) 공유 스트림 구독
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

    // 앱 처음 실행 시 공유된 미디어(텍스트 포함) 가져오기
    ReceiveSharingIntent.instance.getInitialMedia().then((List<SharedMediaFile> sharedFiles) {
      for (final file in sharedFiles) {
        if (file.type == "text/plain") {
          final urls = _extractUrls(file.path);
          for (var url in urls) {
            _viewModel.saveLink(url);
          }
        }
      }
    });

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
            return ListTile(
              title: Text(link.url),
              onTap: () async {
                final uri = Uri.tryParse(link.url);
                if (uri != null && await canLaunchUrl(uri)) {
                  await launchUrl(uri);
                }
              },
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () {
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
