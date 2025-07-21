import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:fluttertrip/views/widgets/zoom_drawer_container.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/shared_link_viewmodel.dart';

class SharedLinkView extends StatefulWidget {
  const SharedLinkView({Key? key}) : super(key: key);

  @override
  _SharedLinkViewState createState() => _SharedLinkViewState();
}

class _SharedLinkViewState extends State<SharedLinkView> {
  int selectedIndex = 2; // 북마크/리스트 탭을 의미하는 인덱스
  late Future<List<SharedLinkModel>> _linkFuture;

  @override
  void initState() {
    super.initState();
    final viewModel = context.read<SharedLinkViewModel>();
    _linkFuture = viewModel.loadSharedLinks();
  }

  void _refresh() {
    setState(() {
      _linkFuture = context.read<SharedLinkViewModel>().loadSharedLinks();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerContainer(
      selectedIndex: selectedIndex,
      onItemSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      mainScreenBuilder: (context) => _buildMainScreen(context),
    );
  }

  @override
  Widget _buildMainScreen(BuildContext context) {
    final viewModel = context.watch<SharedLinkViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '공유된 링크 목록',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              ZoomDrawer.of(context)?.toggle();
            },
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: FutureBuilder<List<SharedLinkModel>>(
        future: _linkFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('오류 발생: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('공유된 링크가 없습니다.'));
          }

          final links = snapshot.data!;
          return ListView.builder(
            itemCount: links.length,
            itemBuilder: (context, index) {
              final link = links[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  title: Text(link.title ?? '제목 없음',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(link.url,
                          style: const TextStyle(color: Colors.blue)),
                      if (link.source != null)
                        Text('출처: ${link.source!}',
                            style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  onTap: () async {
                    final uri = Uri.tryParse(link.url);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    onSelected: (value) async {
                      if (value == 'delete') {
                        await viewModel.deleteLink(link.id);
                        _refresh();
                      } else if (value == 'copy') {
                        await Clipboard.setData(ClipboardData(text: link.url));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('링크가 복사되었습니다.')),
                        );
                      } else if (value == 'share') {
                        await Share.share(link.url);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'copy', child: Text('링크 복사')),
                      const PopupMenuItem(value: 'share', child: Text('공유하기')),
                      const PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
