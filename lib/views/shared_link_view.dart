import 'dart:async';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/shared_link_viewmodel.dart';
import '../design/app_design.dart';

class LinkPreviewData {
  final String? title;
  final String? description;
  final String? image;

  LinkPreviewData({this.title, this.description, this.image});
}

// URL에서 OpenGraph 메타데이터를 파싱하는 함수
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

class _SharedLinkViewState extends State<SharedLinkView>
    with TickerProviderStateMixin {
  late SharedLinkViewModel _viewModel;
  StreamSubscription<List<SharedMediaFile>>? _intentStreamSub;
  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = context.read<SharedLinkViewModel>();
    _initializeAnimations();
    _initializeSharing();
    _viewModel.loadSharedLinks();
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
                    else if (vm.sharedLinks.isEmpty)
                      SliverToBoxAdapter(
                        child: _buildEmptyState(),
                      )
                    else ...[
                        // 통계 카드
                        SliverToBoxAdapter(
                          child: _StatsCard(linkCount: vm.sharedLinks.length),
                        ),

                        // 링크 그리드
                        SliverPadding(
                          padding: const EdgeInsets.all(AppDesign.spacing20),
                          sliver: SliverGrid(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.75,
                              crossAxisSpacing: AppDesign.spacing16,
                              mainAxisSpacing: AppDesign.spacing16,
                            ),
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final link = vm.sharedLinks[index];
                                return _PremiumLinkCard(
                                  url: link.url,
                                  platform: link.platform,
                                  index: index,
                                  onDelete: () {
                                    final id = link.id;
                                    if (id != null) {
                                      vm.deleteLink(id);
                                    }
                                  },
                                );
                              },
                              childCount: vm.sharedLinks.length,
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
                onPressed: () => context.read<SharedLinkViewModel>().loadSharedLinks(),
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
  final String url;
  final String? platform;
  final int index;
  final VoidCallback onDelete;

  const _PremiumLinkCard({
    required this.url,
    this.platform,
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
      final data = await getPreviewData(widget.url);
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

    final platformColor = widget.platform != null
        ? platformColors[widget.platform] ?? AppDesign.travelPurple
        : AppDesign.travelPurple;

    return GestureDetector(
      onTapDown: (_) => _animationController.forward(),
      onTapUp: (_) {
        _animationController.reverse();
        _launchUrl();
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
                            errorBuilder: (_, __, ___) => _buildImagePlaceholder(platformColor),
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
                        if (widget.platform != null)
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
                              widget.platform!,
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
                            _previewData?.title ?? widget.url,
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
                    valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
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

  Future<void> _launchUrl() async {
    final uri = Uri.tryParse(widget.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}