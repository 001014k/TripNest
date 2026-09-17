import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import '../models/link_place_preview_model.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/shared_link_viewmodel.dart';
import '../design/app_design.dart';
import '../widgets/address_photo_preview.dart';

class LinkPreviewData {
  final String? title;
  final String? description;
  final String? image;

  LinkPreviewData({this.title, this.description, this.image});
}

// URL에서 OpenGraph 메타데이터를 파싱하는 함수
Future<LinkPreviewData> getPreviewData(String url) async {
  final sourceUri = Uri.parse(url);
  final response = await http.get(
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

class SharedLinkView extends StatefulWidget {
  const SharedLinkView({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SharedLinkViewModel>();
    _initializeAnimations();
    _initializeSharing();
    _viewModel.subscribeToChanges();
    _viewModel.loadSharedLinks();
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
        print('========== SHARE STREAM ==========');
        print('공유 파일 개수: ${sharedFiles.length}');

        for (final file in sharedFiles) {
          print('------------------------------');
          print('type: ${file.type}');
          print('path: ${file.path}');
          print('mimeType: ${file.mimeType}');
          print('thumbnail: ${file.thumbnail}');
        }

        for (final file in sharedFiles) {
          if (file.type == SharedMediaType.text ||
              file.type == SharedMediaType.url) {
            _handleSharedFile(file);
          }
        }
      },
      onError: (err) {
        print('공유 데이터 수신 오류: $err');
      },
    );

    ReceiveSharingIntent.instance.getInitialMedia().then(
      (List<SharedMediaFile> sharedFiles) {
        print('========== INITIAL SHARE ==========');
        print('공유 파일 개수: ${sharedFiles.length}');

        for (final file in sharedFiles) {
          print('------------------------------');
          print('type: ${file.type}');
          print('path: ${file.path}');
          print('mimeType: ${file.mimeType}');
          print('thumbnail: ${file.thumbnail}');
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

  List<String> _extractUrls(String text) {
    final urlRegex = RegExp(r'https?://[^\s]+');
    return urlRegex.allMatches(text).map((m) => m.group(0)!).toList();
  }

  void _handleSharedFile(SharedMediaFile file) {
    final sharedText = [file.path, file.message]
        .whereType<String>()
        .where((value) => value.trim().isNotEmpty)
        .join('\n');
    final urls = _extractUrls(sharedText);
    for (final url in urls) {
      unawaited(_processSharedUrl(url, sharedText: sharedText));
    }
  }

  Future<void> _processSharedUrl(
    String url, {
    String? sharedText,
  }) async {
    if (!mounted || _isProcessingSharedLink) return;

    _isProcessingSharedLink = true;

    try {
      final platform = _viewModel.detectPlatformFromUrl(url);

      if (platform == 'Instagram') {
        await _processInstagramUrl(
          url,
          sharedText: sharedText,
        );
        return;
      }

      await _processNormalUrl(
        url,
        sharedText: sharedText,
      );
    } catch (e, stackTrace) {
      debugPrint('❌ 링크 처리 실패: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      await _showExtractionFailedDialog(
        '링크를 처리하지 못했습니다.',
      );
    } finally {
      _isProcessingSharedLink = false;
    }
  }

  Future<void> _processNormalUrl(
    String url, {
    String? sharedText,
  }) async {
    _showExtractingDialog();
    var isExtractingDialogVisible = true;

    try {
      final preview = await _viewModel.extractPlacePreview(
        url,
        sharedText: sharedText,
      );

      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
      isExtractingDialogVisible = false;

      await _viewModel.saveLink(
        preview.url,
        placePreview: preview,
      );

      if (!mounted) return;

      if (_viewModel.errorMessage != null) {
        await _showExtractionFailedDialog(
          _viewModel.errorMessage!,
        );
        return;
      }
    } catch (_) {
      if (mounted && isExtractingDialogVisible) {
        Navigator.of(context, rootNavigator: true).pop();
      }
      rethrow;
    }
  }

  Future<void> _processInstagramUrl(
    String url, {
    String? sharedText,
  }) async {
    _showExtractingDialog();
    var isExtractingDialogVisible = true;

    try {
      final previews = await _viewModel.extractInstagramPlaces(
        url,
        sharedText: sharedText,
      );

      if (!mounted) return;

      Navigator.of(
        context,
        rootNavigator: true,
      ).pop();
      isExtractingDialogVisible = false;

      if (previews.isEmpty) {
        await _showExtractionFailedDialog(
          '링크에서 여행 장소를 찾지 못했습니다.',
        );
        return;
      }

      await _viewModel.saveMultiplePlaces(
        url,
        previews,
      );

      if (!mounted) return;

      if (_viewModel.errorMessage != null) {
        await _showExtractionFailedDialog(
          _viewModel.errorMessage!,
        );
        return;
      }
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Instagram 장소 분석 실패: $e',
      );
      debugPrint('$stackTrace');

      if (!mounted) return;

      if (isExtractingDialogVisible) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop();
      }

      await _showExtractionFailedDialog(
        'Instagram에서 여행 장소를 찾지 못했습니다.',
      );
    }
  }

  void _showExtractingDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => PopScope(
        canPop: false,
        child: Dialog(
          child: Padding(
            padding: const EdgeInsets.all(AppDesign.spacing24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                const SizedBox(height: AppDesign.spacing20),
                const Text('장소 정보를 추출 중입니다', style: AppDesign.headingSmall),
                const SizedBox(height: AppDesign.spacing8),
                Text('주소와 미리보기를 준비하고 있어요', style: AppDesign.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
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
              final sourceLinks = linksByUrl.values.toList();

              return FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // 프리미엄 헤더
                    SliverToBoxAdapter(
                      child: _SharedLinkHeader(),
                    ),

                    // 메인 컨텐츠
                    if (vm.errorMessage != null)
                      SliverToBoxAdapter(
                        child: _buildErrorState(vm.errorMessage!),
                      )
                    else if (sourceLinks.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    else ...[
                      // 통계 카드
                      SliverToBoxAdapter(
                        child: _StatsCard(linkCount: sourceLinks.length),
                      ),

                      // 링크 그리드
                      SliverPadding(
                        padding: const EdgeInsets.all(AppDesign.spacing20),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.75,
                            crossAxisSpacing: AppDesign.spacing16,
                            mainAxisSpacing: AppDesign.spacing16,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final link = sourceLinks[index];
                              return _PremiumLinkCard(
                                link: link,
                                index: index,
                                onDelete: () {
                                  vm.deleteLinkGroup(link.url);
                                },
                              );
                            },
                            childCount: sourceLinks.length,
                          ),
                        ),
                      ),
                    ],

                    // 하단 여백
                    const SliverToBoxAdapter(
                      child: SizedBox(height: AppDesign.spacing40),
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
                        AppDesign.travelBlue.withOpacity(0.1),
                        AppDesign.travelPurple.withOpacity(0.1),
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
            description: '인스타그램, 유튜브 링크를 공유하세요',
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
                icon: const Icon(Icons.refresh_rounded),
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
                                if (preview.address != null &&
                                    preview.address!.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    preview.address!,
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

class _LinkPlacePreviewPage extends StatelessWidget {
  const _LinkPlacePreviewPage({
    required this.preview,
    required this.onSearch,
  });

  final LinkPlacePreview preview;
  final Future<List<LinkPlacePreview>> Function(String query) onSearch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      appBar: AppBar(
        backgroundColor: AppDesign.primaryBg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text('장소 확인', style: AppDesign.headingSmall),
      ),
      body: _LinkPlacePreviewSheet(
        preview: preview,
        onSearch: onSearch,
      ),
    );
  }
}

class _LinkPlacePreviewSheet extends StatefulWidget {
  const _LinkPlacePreviewSheet({
    required this.preview,
    required this.onSearch,
  });

  final LinkPlacePreview preview;
  final Future<List<LinkPlacePreview>> Function(String query) onSearch;

  @override
  State<_LinkPlacePreviewSheet> createState() => _LinkPlacePreviewSheetState();
}

class _LinkPlacePreviewSheetState extends State<_LinkPlacePreviewSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _addressController;
  bool _isEditing = false;
  bool _isSearching = false;
  List<LinkPlacePreview> _searchResults = const [];
  late LinkPlacePreview _selectedPreview;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.preview.title);
    _addressController = TextEditingController(text: widget.preview.address);
    _selectedPreview = widget.preview;
    _isEditing = widget.preview.title.isEmpty;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _searchPlaces() async {
    final query = '${_titleController.text} ${_addressController.text}'.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    try {
      final results = await widget.onSearch(query);
      if (!mounted) return;
      setState(() => _searchResults = results);
    } catch (_) {
      if (mounted) setState(() => _searchResults = const []);
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _selectPlace(LinkPlacePreview preview) {
    setState(() {
      _selectedPreview = preview;
      _titleController.text = preview.title;
      _addressController.text = preview.address;
      _searchResults = const [];
      _isEditing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(AppDesign.spacing12),
        padding: const EdgeInsets.fromLTRB(
          AppDesign.spacing20,
          AppDesign.spacing10,
          AppDesign.spacing20,
          AppDesign.spacing20,
        ),
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          boxShadow: AppDesign.elevatedShadow,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppDesign.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppDesign.spacing20),
              Text(
                widget.preview.title.isEmpty ? '장소명을 확인해주세요' : '장소를 찾았어요',
                style: AppDesign.headingMedium,
              ),
              const SizedBox(height: AppDesign.spacing4),
              Text(
                widget.preview.title.isEmpty
                    ? '장소명을 확인하지 못했습니다. 장소를 검색하거나 직접 입력해주세요.'
                    : '장소명이나 주소가 다르면 수정한 뒤 저장해주세요.',
                style: AppDesign.bodySmall
                    .copyWith(color: AppDesign.secondaryText),
              ),
              const SizedBox(height: AppDesign.spacing16),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                child: AddressPhotoPreview(
                  address: _selectedPreview.address,
                  title: _selectedPreview.title,
                  size: 168,
                ),
              ),
              const SizedBox(height: AppDesign.spacing16),
              Row(
                children: [
                  Text('장소',
                      style: AppDesign.bodySmall
                          .copyWith(color: AppDesign.subtleText)),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () => setState(() => _isEditing = !_isEditing),
                    icon: Icon(
                        _isEditing ? Icons.check_rounded : Icons.edit_outlined,
                        size: 16),
                    label: Text(_isEditing ? '완료' : '수정'),
                  ),
                ],
              ),
              const SizedBox(height: AppDesign.spacing4),
              _isEditing
                  ? TextField(
                      controller: _titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(isDense: true),
                    )
                  : Text(
                      _titleController.text.isEmpty
                          ? '장소명 확인 필요'
                          : _titleController.text,
                      style: AppDesign.headingSmall,
                    ),
              const SizedBox(height: AppDesign.spacing12),
              Text('주소',
                  style: AppDesign.bodySmall
                      .copyWith(color: AppDesign.subtleText)),
              const SizedBox(height: AppDesign.spacing4),
              _isEditing
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _addressController,
                          minLines: 1,
                          maxLines: 2,
                          decoration: const InputDecoration(isDense: true),
                        ),
                        const SizedBox(height: AppDesign.spacing8),
                        OutlinedButton.icon(
                          onPressed: _isSearching ? null : _searchPlaces,
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.search_rounded, size: 18),
                          label: const Text('장소 다시 찾기'),
                        ),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.location_on_outlined,
                            size: 18,
                            color: AppDesign.travelBlue,
                          ),
                        ),
                        const SizedBox(width: AppDesign.spacing6),
                        Expanded(
                          child: Text(_addressController.text,
                              style: AppDesign.bodyMedium),
                        ),
                      ],
                    ),
              if (_searchResults.isNotEmpty) ...[
                const SizedBox(height: AppDesign.spacing12),
                Text('검색 결과',
                    style: AppDesign.bodySmall
                        .copyWith(color: AppDesign.subtleText)),
                const SizedBox(height: AppDesign.spacing4),
                ..._searchResults.map(
                  (place) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.place_outlined,
                        color: AppDesign.travelBlue),
                    title: Text(place.title,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(place.address,
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () => _selectPlace(place),
                  ),
                ),
              ],
              const SizedBox(height: AppDesign.spacing20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        foregroundColor: AppDesign.primaryText,
                        side: const BorderSide(color: AppDesign.borderColor),
                      ),
                      child: const Text('취소'),
                    ),
                  ),
                  const SizedBox(width: AppDesign.spacing12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final title = _titleController.text.trim();
                        final address = _addressController.text.trim();
                        if (title.isEmpty || address.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('장소명과 주소를 입력해주세요.')),
                          );
                          return;
                        }
                        final changed = title != _selectedPreview.title ||
                            address != _selectedPreview.address;
                        Navigator.pop(
                          context,
                          _selectedPreview.copyWith(
                            title: title,
                            address: address,
                            clearLocation: changed,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        backgroundColor: AppDesign.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('저장하기'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// 프리미엄 헤더 위젯
class _SharedLinkHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  boxShadow: AppDesign.softShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    onTap: () => Navigator.pop(context),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppDesign.primaryText,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing12),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing32),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppDesign.travelBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppDesign.travelBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '링크 컬렉션',
              style: AppDesign.caption.copyWith(
                color: AppDesign.travelBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spacing12),
          const Text('공유된 링크', style: AppDesign.headingXL),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '여행 정보를 한 곳에서 관리하세요 📌',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}

// 통계 카드 위젯
class _StatsCard extends StatelessWidget {
  final int linkCount;

  const _StatsCard({required this.linkCount});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppDesign.sunsetGradientStart.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.analytics_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDesign.spacing20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '총 $linkCount개의 링크',
                  style: AppDesign.headingMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  '여행 정보가 차곡차곡 쌓이고 있어요',
                  style: AppDesign.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
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

// 가이드 카드 위젯
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
              color: color.withOpacity(0.1),
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

class _PremiumLinkCardState extends State<_PremiumLinkCard>
    with SingleTickerProviderStateMixin {
  LinkPreviewData? _previewData;
  bool _loading = true;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimation();
    _fetchPreview();
  }

  void _initializeAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
  }

  Future<void> _fetchPreview() async {
    try {
      final data = await getPreviewData(widget.link.url);
      if (mounted) {
        setState(() {
          _previewData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return _buildLoadingCard();
    }

    final platformColors = {
      'Instagram': AppDesign.sunsetGradientStart,
      'YouTube': Colors.red,
      'Twitter': AppDesign.travelBlue,
      'Facebook': const Color(0xFF1877F2),
      'LinkedIn': const Color(0xFF0A66C2),
    };

    final platformColor =
        platformColors[widget.link.platform] ?? AppDesign.travelPurple;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        Navigator.pushNamed(context, '/shared_link_detail',
            arguments: widget.link);
      },
      onTapCancel: () => _animationController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.elevatedShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 이미지 섹션
                Expanded(
                  flex: 3,
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppDesign.radiusLarge),
                        ),
                        child: Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: _previewData?.image == null
                                ? LinearGradient(
                                    colors: [
                                      platformColor.withOpacity(0.8),
                                      platformColor.withOpacity(0.4),
                                    ],
                                  )
                                : null,
                          ),
                          child: _previewData?.image != null
                              ? Image.network(
                                  _previewData!.image!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      _buildImagePlaceholder(platformColor),
                                )
                              : _buildImagePlaceholder(platformColor),
                        ),
                      ),
                      // 삭제 버튼
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppDesign.primaryText.withOpacity(0.7),
                            shape: BoxShape.circle,
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(20),
                              onTap: widget.onDelete,
                              child: const Padding(
                                padding: EdgeInsets.all(6),
                                child: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 콘텐츠 섹션
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: const EdgeInsets.all(AppDesign.spacing12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: platformColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.link.platform,
                            style: TextStyle(
                              color: platformColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: Text(
                            _previewData?.title ??
                                widget.link.placeTitle ??
                                widget.link.url,
                            style: AppDesign.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            softWrap: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
      color: color.withOpacity(0.1),
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
