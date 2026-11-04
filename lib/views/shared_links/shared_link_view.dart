import '../../widgets/onboarding/shared_link_guide_button.dart';
import '../../services/shared_links/shared_link_platform.dart';
import '../../widgets/common/app_overlays.dart';
import '../../widgets/common/reference_design.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../../models/shared_links/link_place_preview_model.dart';
import '../../models/shared_links/link_preview_data.dart';
import '../../models/shared_links/shared_link_model.dart';
import '../../viewmodels/shared_links/shared_link_viewmodel.dart';
import '../../design/app_design.dart';

class SharedLinkView extends StatefulWidget {
  const SharedLinkView({super.key, this.showGuide = false});
  final bool showGuide;

  @override
  State<SharedLinkView> createState() => _SharedLinkViewState();
}

class _SharedLinkViewState extends State<SharedLinkView>
    with TickerProviderStateMixin {
  late SharedLinkViewModel _viewModel;
  StreamSubscription<List<SharedMediaFile>>? _intentStreamSub;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  bool _isProcessingSharedLink = false;
  String _query = '';
  String? _platform;
  bool _incomingShare = false;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SharedLinkViewModel>();
    _incomingShare = _viewModel.hasPendingSharedUrl;
    _initializeAnimations();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _initializeSharing();
      _viewModel.subscribeToChanges();
      unawaited(_viewModel.loadSharedLinks());
      final pendingLink = _viewModel.consumePendingSharedLink();

      if (pendingLink != null) {
        unawaited(
          _processSharedUrl(
            pendingLink.url,
            sharedText: pendingLink.sharedText,
          ),
        );
      }
    });
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );
    _fadeAnimationController.forward();
  }

  void _initializeSharing() {
    _intentStreamSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      (List<SharedMediaFile> sharedFiles) {
        debugPrint('========== SHARE STREAM ==========');
        debugPrint('공유 파일 개수: ${sharedFiles.length}');

        for (final file in sharedFiles) {
          debugPrint('------------------------------');
          debugPrint('type: ${file.type}');
          debugPrint('path: ${file.path}');
          debugPrint('mimeType: ${file.mimeType}');
          debugPrint('thumbnail: ${file.thumbnail}');
        }

        for (final file in sharedFiles) {
          if (file.type == SharedMediaType.text ||
              file.type == SharedMediaType.url) {
            _handleSharedFile(file);
          }
        }
      },
      onError: (err) {
        debugPrint('공유 데이터 수신 오류: $err');
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then(
      (List<SharedMediaFile> sharedFiles) {
        debugPrint('========== INITIAL SHARE ==========');
        debugPrint('공유 파일 개수: ${sharedFiles.length}');

        for (final file in sharedFiles) {
          debugPrint('------------------------------');
          debugPrint('type: ${file.type}');
          debugPrint('path: ${file.path}');
          debugPrint('mimeType: ${file.mimeType}');
          debugPrint('thumbnail: ${file.thumbnail}');
        }

        for (final file in sharedFiles) {
          if (file.type == SharedMediaType.text ||
              file.type == SharedMediaType.url) {
            _handleSharedFile(file);
          }
        }
      },
    );
  }

  @override
  void dispose() {
    _intentStreamSub?.cancel();
    _fadeAnimationController.dispose();
    super.dispose();
  }

  void _handleSharedFile(SharedMediaFile file) {
    final sharedText = [file.path, file.message]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join('\n');
    final urls = _viewModel.extractUrls(sharedText);
    for (final url in urls) {
      unawaited(_processSharedUrl(url, sharedText: sharedText));
    }
  }

  Future<void> _processSharedUrl(
    String url, {
    String? sharedText,
  }) async {
    if (!mounted || _isProcessingSharedLink) return;

    setState(() => _isProcessingSharedLink = true);

    final progress = ValueNotifier<int>(0);
    final navigator = Navigator.of(context, rootNavigator: true);
    final dialog = DialogRoute<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LinkProgressDialog(progress: progress),
    );
    unawaited(navigator.push(dialog));
    String? failure;
    SharedLinkModel? savedLink;
    var savedUrl = url;
    try {
      final platform = _viewModel.detectPlatformFromUrl(url);
      final multiPlace = platform == 'Instagram' ||
          platform == 'Threads' ||
          SharedLinkPlatform.supportsPlaces(url);
      if (!multiPlace && SharedLinkPlatform.isExcludedPortal(url)) {
        throw const FormatException(
            '지도·검색 결과 대신 장소 후기가 담긴 블로그·카페 글의 링크를 공유해주세요.');
      }
      progress.value = 1;
      if (multiPlace) {
        final List<LinkPlacePreview> places;
        if (platform == 'Instagram') {
          places = await _viewModel.extractInstagramPlaces(url,
              sharedText: sharedText);
        } else if (platform == 'Threads') {
          places = await _viewModel.extractThreadsPlaces(url);
        } else {
          places =
              await _viewModel.extractPortalPlaces(url, sharedText: sharedText);
        }
        if (!mounted) return;
        if (places.isEmpty) {
          throw FormatException(
              _viewModel.errorMessage ?? '링크에서 여행 장소를 찾지 못했습니다.');
        }
        progress.value = 2;
        await _viewModel.saveMultiplePlaces(url, places);
      } else {
        final preview =
            await _viewModel.extractPlacePreview(url, sharedText: sharedText);
        if (!mounted) return;
        progress.value = 2;
        savedUrl = preview.url;
        await _viewModel.saveLink(preview.url, placePreview: preview);
      }
      if (!mounted) return;
      failure = _viewModel.errorMessage;
      if (failure == null) {
        // Duplicate links can skip insertion, so refresh if the saved link
        // has not reached the local list yet.
        if (!_viewModel.sharedLinks.any((link) => link.url == savedUrl)) {
          await _viewModel.loadSharedLinks();
          if (!mounted) return;
        }
        for (final link in _viewModel.sharedLinks) {
          if (link.url == savedUrl) {
            savedLink = link;
            break;
          }
        }
        if (multiPlace) {
          setState(() {
            _query = '';
            _platform = null;
          });
        }
        progress.value = 3;
        await Future<void>.delayed(const Duration(milliseconds: 480));
      }
    } catch (error, stackTrace) {
      debugPrint('링크 처리 실패: $error\n$stackTrace');
      failure = error is FormatException ? error.message : '링크를 처리하지 못했습니다.';
    } finally {
      if (dialog.isActive) navigator.removeRoute(dialog);
      await dialog.completed;
      progress.dispose();
      if (mounted) {
        try {
          if (failure != null) await _showExtractionFailedDialog(failure);
        } finally {
          if (mounted) {
            setState(() {
              _isProcessingSharedLink = false;
              _incomingShare = false;
            });
          }
        }
      }
    }
    if (mounted && failure == null && savedLink != null) {
      unawaited(Navigator.pushNamed(
        context,
        '/shared_link_detail',
        arguments: savedLink,
      ));
    } else if (mounted && failure == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('링크 저장 처리는 완료했지만 상세 정보를 불러오지 못했어요. 목록을 새로고침해주세요.'),
      ));
    }
  }

  Future<void> _showExtractionFailedDialog(String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('장소를 찾지 못했어요'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Consumer<SharedLinkViewModel>(
        builder: (context, vm, child) => SharedLinkGuideButton(
          floating: true,
          forceGuide: widget.showGuide,
          enabled:
              !_incomingShare && !_isProcessingSharedLink && !vm.isLoadingLinks,
          onPressed: _addLink,
        ),
      ),
      bottomNavigationBar:
          const TripNestNavigation(currentRoute: '/shared_link'),
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDesign.backgroundGradient,
        ),
        child: SafeArea(
          child: Consumer<SharedLinkViewModel>(
            builder: (context, vm, child) {
              // A source link can contain multiple extracted places. Keep the
              // overview to one card per URL and show places in its detail.
              final linksByUrl = <String, SharedLinkModel>{};
              for (final link in vm.sharedLinks) {
                linksByUrl.putIfAbsent(link.url, () => link);
              }
              final sourceLinks = linksByUrl.values
                  .where((link) =>
                      (_platform == null || link.platform == _platform) &&
                      '${link.placeTitle ?? ''} ${link.url}'
                          .toLowerCase()
                          .contains(_query.toLowerCase()))
                  .toList();

              return FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    const SliverToBoxAdapter(child: _SharedLinkHeader()),
                    SliverToBoxAdapter(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: ReferenceSearch(
                                onChanged: (value) =>
                                    setState(() => _query = value),
                                onFilter: _choosePlatform))),
                    const SliverToBoxAdapter(child: SizedBox(height: 12)),
                    SliverToBoxAdapter(
                      child: const SizedBox.shrink(),
                    ),

                    // 메인 컨텐츠
                    if (vm.isLoadingLinks && sourceLinks.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                              vertical: AppDesign.spacing48),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      )
                    else if (vm.errorMessage != null)
                      SliverToBoxAdapter(
                        child: _buildErrorState(vm.errorMessage!),
                      )
                    else if (sourceLinks.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    else ...[
                      // 통계 카드

                      // 링크 그리드
                      SliverPadding(
                        padding: const EdgeInsets.all(AppDesign.spacing20),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final link = sourceLinks[index];
                              return Padding(
                                  key: ValueKey(link.url),
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _PremiumLinkCard(
                                    link: link,
                                    index: index,
                                    onDelete: () {
                                      vm.deleteLinkGroup(link.url);
                                    },
                                  ));
                            },
                            childCount: sourceLinks.length,
                          ),
                        ),
                      ),
                    ],

                    // 하단 여백
                    const SliverToBoxAdapter(
                      child: SizedBox(height: 96),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _addLink() async {
    final url = await showDialog<String>(
        context: context,
        builder: (_) => const AppTextInputDialog(
            title: '새 링크 가져오기',
            subtitle: '저장할 게시물이나 장소의 링크를 붙여넣어주세요.',
            hint: 'https://…',
            submitLabel: '가져오기',
            keyboardType: TextInputType.url,
            icon: Icons.link_rounded));
    if (url == null || url.isEmpty || !mounted) return;
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('올바른 링크를 입력해주세요.')));
      return;
    }
    await _processSharedUrl(url);
  }

  Future<void> _choosePlatform() async {
    final platforms =
        _viewModel.sharedLinks.map((e) => e.platform).toSet().toList();
    final choice = await showAppSheet<String>(
      context: context,
      builder: (sheet) => AppSheet(
        title: '플랫폼 선택',
        subtitle: '원하는 플랫폼의 저장한 링크만 모아보세요.',
        children: [
          for (final name in ['전체', ...platforms])
            AppSheetOption(
              title: name,
              icon: Icons.link_rounded,
              selected: (_platform ?? '전체') == name,
              onTap: () => Navigator.pop(sheet, name),
            )
        ],
      ),
    );
    if (choice != null && mounted) {
      setState(() => _platform = choice == '전체' ? null : choice);
    }
  }

  Widget _buildEmptyState() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(AppDesign.spacing32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 애니메이션 아이콘
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 1000),
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppDesign.travelBlue.withValues(alpha: 0.1),
                        AppDesign.travelPurple.withValues(alpha: 0.1),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.share_outlined,
                    color: AppDesign.travelBlue,
                    size: 70,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppDesign.spacing32),
          Text(
            '아직 공유된 링크가 없어요',
            style: AppDesign.headingLarge,
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            '다른 앱에서 링크를 공유하면\n여기에 자동으로 저장됩니다',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesign.spacing40),

          // 가이드 카드들
          _GuideCard(
            icon: Icons.web,
            title: '브라우저에서',
            description: '웹페이지 공유 버튼을 눌러보세요',
            color: AppDesign.travelBlue,
          ),
          const SizedBox(height: AppDesign.spacing12),
          _GuideCard(
            icon: Icons.photo_library_outlined,
            title: 'SNS에서',
            description: '인스타그램·Threads 또는 공개 블로그·카페 글을 공유하세요',
            color: AppDesign.sunsetGradientStart,
          ),
          const SizedBox(height: AppDesign.spacing12),
          _GuideCard(
            icon: Icons.bookmark_outline,
            title: '자동 저장',
            description: '공유한 링크가 자동으로 정리됩니다',
            color: AppDesign.travelGreen,
          ),

          // 화면 끝에 여백 확보 (스크롤이 자연스럽게 끝나도록)
          const SizedBox(height: AppDesign.spacing80),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.5,
      padding: const EdgeInsets.all(AppDesign.spacing32),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(AppDesign.spacing32),
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
            boxShadow: AppDesign.elevatedShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.red.shade400,
                      Colors.orange.shade400,
                    ],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppDesign.spacing24),
              Text(
                '문제가 발생했어요',
                style: AppDesign.headingMedium,
              ),
              const SizedBox(height: AppDesign.spacing8),
              Text(
                error,
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppDesign.spacing24),
              ElevatedButton.icon(
                onPressed: () =>
                    context.read<SharedLinkViewModel>().loadSharedLinks(),
                icon: const Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                label: const Text('다시 시도'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppDesign.primaryText,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.spacing24,
                    vertical: AppDesign.spacing12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InstagramPlaceSelectionPage extends StatefulWidget {
  final List<LinkPlacePreview> previews;

  const _InstagramPlaceSelectionPage({
    required this.previews,
  });

  @override
  State<_InstagramPlaceSelectionPage> createState() =>
      _InstagramPlaceSelectionPageState();
}

class _InstagramPlaceSelectionPageState
    extends State<_InstagramPlaceSelectionPage> {
  late List<bool> _selected;

  @override
  void initState() {
    super.initState();

    // 기본값: 모든 장소 선택
    _selected = List<bool>.filled(
      widget.previews.length,
      true,
    );
  }

  List<LinkPlacePreview> get _selectedPlaces {
    final result = <LinkPlacePreview>[];

    for (var i = 0; i < widget.previews.length; i++) {
      if (_selected[i]) {
        result.add(widget.previews[i]);
      }
    }

    return result;
  }

  void _togglePlace(int index) {
    setState(() {
      _selected[index] = !_selected[index];
    });
  }

  void _saveSelectedPlaces() {
    final selectedPlaces = _selectedPlaces;

    if (selectedPlaces.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('최소 하나의 장소를 선택해주세요.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(selectedPlaces);
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _selectedPlaces.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instagram 장소 선택'),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.previews.length,
              itemBuilder: (context, index) {
                final preview = widget.previews[index];
                final isSelected = _selected[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _togglePlace(index),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: isSelected,
                            onChanged: (_) => _togglePlace(index),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  preview.title,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (preview.address.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    preview.address,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                16,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedCount == 0 ? null : _saveSelectedPlaces,
                  child: Text(
                    '$selectedCount개 장소 저장',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedLinkHeader extends StatelessWidget {
  const _SharedLinkHeader();

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const TripNestHeader(),
          const SizedBox(height: 20),
          const Text('공유 링크', style: AppDesign.headingLarge),
          const SizedBox(height: 6),
          const Text('저장한 링크에서 장소를 확인해보세요.', style: AppDesign.bodySmall),
        ]),
      );
}

// 통계 카드 위젯
class _GuideCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _GuideCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesign.spacing12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
            ),
            child: Icon(
              icon,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppDesign.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  description,
                  style: AppDesign.caption.copyWith(
                    color: AppDesign.secondaryText,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 프리미엄 링크 카드 위젯
class _PremiumLinkCard extends StatefulWidget {
  final SharedLinkModel link;
  final int index;
  final VoidCallback onDelete;

  const _PremiumLinkCard({
    required this.link,
    required this.index,
    required this.onDelete,
  });

  @override
  State<_PremiumLinkCard> createState() => _PremiumLinkCardState();
}

class _PremiumLinkCardState extends State<_PremiumLinkCard> {
  LinkPreviewData? _previewData;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchPreview();
  }

  Future<void> _fetchPreview() async {
    try {
      final data = await context
          .read<SharedLinkViewModel>()
          .loadPreview(widget.link.url);
      if (mounted) {
        setState(() {
          _previewData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          debugPrint('링크 미리보기 로드 실패: $e');
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return SizedBox(height: 170, child: _buildLoadingCard());
    }

    final platformColors = {
      'Instagram': AppDesign.sunsetGradientStart,
      'Threads': const Color(0xFF222222),
      'YouTube': Colors.red,
      'Twitter': AppDesign.travelBlue,
      'Facebook': const Color(0xFF1877F2),
      'LinkedIn': const Color(0xFF0A66C2),
    };

    final platformColor =
        platformColors[widget.link.platform] ?? AppDesign.travelPurple;

    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: AppDesign.borderColor)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/shared_link_detail',
            arguments: widget.link),
        child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                      width: 84,
                      height: 94,
                      child: _previewData?.image != null
                          ? Image.network(_previewData!.image!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  _buildImagePlaceholder(platformColor))
                          : _buildImagePlaceholder(platformColor))),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    ReferencePlatform(platform: widget.link.platform),
                    const SizedBox(height: 5),
                    Text(
                        _previewData?.title ??
                            widget.link.placeTitle ??
                            widget.link.url,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesign.bodyMedium
                            .copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(widget.link.url,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppDesign.caption),
                    const SizedBox(height: 8),
                    Text(_savedAge(widget.link.createdAt),
                        style: AppDesign.caption),
                    const SizedBox(height: 10),
                    Builder(builder: (context) {
                      final places = context
                          .watch<SharedLinkViewModel>()
                          .sharedLinks
                          .where((item) =>
                              item.url == widget.link.url &&
                              (item.placeAddress?.isNotEmpty ?? false))
                          .toList();
                      return Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 5,
                          children: [
                            for (final place in places.take(3))
                              ReferencePhoto(
                                  title: place.placeTitle ?? '',
                                  address: place.placeAddress!,
                                  width: 30,
                                  height: 30),
                            Text('장소 ${places.length}개 추출됨  ›',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: AppDesign.secondaryText)),
                          ]);
                    }),
                  ])),
              SizedBox(
                  width: 24,
                  child: PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert,
                          size: 20, color: AppDesign.secondaryText),
                      onSelected: (_) => widget.onDelete(),
                      itemBuilder: (_) => [
                            const PopupMenuItem(
                                value: 'delete', child: Text('링크 삭제'))
                          ])),
            ])),
      ),
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        children: [
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppDesign.lightGray,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(AppDesign.radiusLarge),
                ),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(AppDesign.spacing12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 12,
                    width: 60,
                    decoration: BoxDecoration(
                      color: AppDesign.lightGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 14,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppDesign.lightGray,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(Color color) {
    return Container(
      color: color.withValues(alpha: 0.1),
      child: Center(
        child: Icon(
          Icons.link_rounded,
          color: color,
          size: 32,
        ),
      ),
    );
  }
}

String _savedAge(DateTime date) {
  final difference = DateTime.now().difference(date.toLocal());
  if (difference.inMinutes < 1) return '방금 저장함';
  if (difference.inHours < 1) return '${difference.inMinutes}분 전 저장함';
  if (difference.inDays < 1) return '${difference.inHours}시간 전 저장함';
  if (difference.inDays == 1) return '어제 저장함';
  return '${date.month}월 ${date.day}일 저장함';
}

class _LinkProgressDialog extends StatelessWidget {
  const _LinkProgressDialog({required this.progress});
  final ValueNotifier<int> progress;

  static const labels = ['링크 확인', '장소 추출', '저장'];
  static const messages = [
    '공유된 링크를 확인하고 있어요',
    '링크 속 장소를 찾고 있어요',
    '링크 정보를 저장하고 있어요',
    '공유 링크를 저장했어요',
  ];

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: Dialog(
          backgroundColor: AppDesign.homeSurface,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ValueListenableBuilder<int>(
              valueListenable: progress,
              builder: (context, count, _) => Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: const Color(0xfff1f1f3),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.link_rounded,
                            color: AppDesign.homeForeground)),
                    const SizedBox(width: 10),
                    const Text('공유 링크 저장',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppDesign.homeForeground)),
                  ]),
                  const SizedBox(height: 16),
                  Semantics(
                      liveRegion: true,
                      child: Text(messages[count],
                          style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppDesign.homeForeground))),
                  const SizedBox(height: 18),
                  Row(children: [
                    const Expanded(child: Text('진행 상황')),
                    Text('$count/3단계 완료',
                        style: const TextStyle(fontWeight: FontWeight.w700)),
                  ]),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                      tween:
                          Tween<double>(begin: 0, end: count / labels.length),
                      duration: MediaQuery.disableAnimationsOf(context)
                          ? Duration.zero
                          : const Duration(milliseconds: 220),
                      builder: (_, value, __) => LinearProgressIndicator(
                          value: value,
                          minHeight: 10,
                          borderRadius: BorderRadius.circular(12),
                          color: AppDesign.homeForeground,
                          backgroundColor: AppDesign.homeSurfaceBorder,
                          semanticsLabel: '공유 링크 저장 진행 상황',
                          semanticsValue: '$count/3단계 완료')),
                  const SizedBox(height: 12),
                  Wrap(spacing: 12, runSpacing: 6, children: [
                    for (var i = 0; i < labels.length; i++)
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                            i < count
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked,
                            size: 17,
                            color: AppDesign.homeForeground),
                        const SizedBox(width: 4),
                        Text(labels[i], style: const TextStyle(fontSize: 12)),
                      ]),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
