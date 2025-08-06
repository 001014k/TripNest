import 'package:flutter/material.dart';
import 'package:fluttertrip/views/shared_link_view.dart';
import 'package:fluttertrip/views/widgets/preview_card.dart';
import 'package:provider/provider.dart';
import '../models/shared_link_model.dart';
import '../viewmodels/home_viewmodel.dart';
import '../models/marker_model.dart';

// constants.dart (또는 styles.dart)
const double kHorizontalPadding = 20;
const double kVerticalPadding = 16;
const double kSectionSpacing = 32;
const double kItemSpacing = 12;

// main_theme.dart (필요시 다크 모드 포함 테마로 교체 가능)
final ThemeData appTheme = ThemeData(
  brightness: Brightness.light,
  primaryColor: Colors.black,
  colorScheme: ColorScheme.light(
    primary: Colors.black,
    secondary: Colors.grey.shade600,
  ),
  textTheme: const TextTheme(
    headlineSmall: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
    titleLarge: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
    titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
    bodyMedium: TextStyle(fontSize: 14),
    bodySmall: TextStyle(fontSize: 12, color: Colors.grey),
  ),
);

class HomeDashboardView extends StatefulWidget {
  const HomeDashboardView({super.key});

  @override
  State<HomeDashboardView> createState() => _HomeDashboardViewState();
}

class _HomeDashboardViewState extends State<HomeDashboardView> {
  @override
  void initState() {
    super.initState();
    final viewModel = context.read<HomeDashboardViewModel>();
    viewModel.loadRecentMarkers();
    viewModel.loadSharedLinks();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<HomeDashboardViewModel>();
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildGreeting(theme),
              const SizedBox(height: kSectionSpacing),
              FeatureSection(
                onMapTap: () => Navigator.pushNamed(context, '/map'),
                onListTap: () => Navigator.pushNamed(context, '/list'),
              ),
              const SizedBox(height: kSectionSpacing),
              FriendsPlanCard(
                  onTap: () => Navigator.pushNamed(context, '/friends')),
              const SizedBox(height: kSectionSpacing),
              if (viewModel.recentMarkers.isNotEmpty)
                RecentMarkersSection(
                  markers: viewModel.recentMarkers,
                  onViewAll: () => Navigator.pushNamed(context, '/list'),
                ),
              const SizedBox(height: kSectionSpacing),
              if (viewModel.sharedLinks.isNotEmpty)
                SharedLinksSection(
                  sharedLinks: viewModel.sharedLinks,
                  onViewAll: () =>
                      Navigator.pushNamed(context, '/shared_links'),
                ),
              const SizedBox(height: kVerticalPadding),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGreeting(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '새로운 여정을 떠날 준비가 되셧나요?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '여기서 당신만의 여행을 설계해보세요?',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.grey[600],
            fontSize: 15,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}

  class FeatureCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadiusGeometry borderRadius;

  const FeatureCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    super.key,
  });

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _pressed = false;

  void _onTapDown(TapDownDetails details) {
    setState(() {
      _pressed = true;
    });
  }

  void _onTapUp(TapUpDetails details) {
    setState(() {
      _pressed = false;
    });
  }

  void _onTapCancel() {
    setState(() {
      _pressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: widget.padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: _pressed
            ? []
            : [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        child: widget.child,
      ),
    );
  }
}

class FeatureSection extends StatelessWidget {
  final VoidCallback onMapTap;
  final VoidCallback onListTap;

  const FeatureSection({
    required this.onMapTap,
    required this.onListTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FeatureCard(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _FeatureButton(
            icon: Icons.map,
            label: '여행지 탐색',
            description: '지도를 탐험하며\n새로운 장소를 발견하세요',
            onTap: onMapTap,
          ),
          _FeatureButton(
            icon: Icons.list_alt,
            label: '여행 노트',
            description: '마음에 드는 장소를\n리스트에 담아보세요',
            onTap: onListTap,
          ),
        ],
      ),
    );
  }
}

class FriendsPlanCard extends StatelessWidget {
  final VoidCallback onTap;

  const FriendsPlanCard({required this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FeatureCard(
      color: Colors.blue[50],
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            children: [
              Icon(Icons.group, size: 48, color: Colors.blue[700]),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '함께 떠나는 여행',
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.blue[800]),
                    ),
                    Text(
                      '친구와 함께 일정을 짜고, 추억을 만들어보세요.',
                      style: theme.textTheme.bodyMedium?.copyWith(color: Colors.blue[700]),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.blue[700]),
            ],
          ),
        ),
      ),
    );
  }
}

class RecentMarkersSection extends StatefulWidget {
  final List<MarkerModel> markers;
  final VoidCallback onViewAll;

  const RecentMarkersSection({
    required this.markers,
    required this.onViewAll,
    super.key,
  });

  @override
  State<RecentMarkersSection> createState() => _RecentMarkersSectionState();
}

class _RecentMarkersSectionState extends State<RecentMarkersSection> {
  final Map<String, LinkPreviewData?> _previewDataMap = {};
  final Set<String> _loadingUrls = {};

  @override
  void initState() {
    super.initState();
    _fetchPreviews();
  }

  Future<void> _fetchPreviews() async {
    for (final marker in widget.markers) {
      final url = marker.address;
      if (url.isEmpty) continue;
      if (_previewDataMap.containsKey(url) || _loadingUrls.contains(url)) continue;

      _loadingUrls.add(url);

      try {
        final previewData = await getPreviewData(url);
        if (mounted) {
          setState(() {
            _previewDataMap[url] = previewData;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _previewDataMap[url] = null;
          });
        }
      }
      _loadingUrls.remove(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.location_on,
          title: '최근 저장한 장소',
          onViewAll: widget.onViewAll,
        ),
        const SizedBox(height: kItemSpacing),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.markers.length,
            separatorBuilder: (_, __) => const SizedBox(width: kItemSpacing),
            itemBuilder: (context, index) {
              final marker = widget.markers[index];
              final previewData = _previewDataMap[marker.address];

              return PreviewCard(
                title: previewData?.title ?? marker.title,
                subtitle: previewData?.description ?? marker.address,
                imageUrl: previewData?.image,
                width: 280,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/user_list',
                    arguments: marker.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.onTap,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(20),
              child: Icon(icon, size: 48, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onViewAll;

  const SectionHeader({
    required this.title,
    required this.icon,
    required this.onViewAll,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: theme.colorScheme.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: onViewAll,
          child: Text(
            '전체 보기',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.blueAccent,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}



class SharedLinksSection extends StatefulWidget {
  final List<SharedLinkModel> sharedLinks;
  final VoidCallback? onViewAll;

  const SharedLinksSection({
    required this.sharedLinks,
    this.onViewAll,
    Key? key,
  }) : super(key: key);

  @override
  State<SharedLinksSection> createState() => _SharedLinksSectionState();
}

class _SharedLinksSectionState extends State<SharedLinksSection> {
  final Map<String, LinkPreviewData> _previewDataMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAllPreviewData();
  }

  Future<void> _loadAllPreviewData() async {
    for (final link in widget.sharedLinks) {
      try {
        final preview = await getPreviewData(link.url);
        _previewDataMap[link.url] = preview;
      } catch (e) {
        _previewDataMap[link.url] = LinkPreviewData(
          title: link.platform,
          description: '',
          image: null,
        );
      }
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.sharedLinks.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.share,
          title: '공유된 링크',
          onViewAll: widget.onViewAll ?? () {
            Navigator.pushNamed(context, '/shared_links');
          },
        ),
        const SizedBox(height: kItemSpacing),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: widget.sharedLinks.length,
            separatorBuilder: (_, __) => const SizedBox(width: kItemSpacing),
            itemBuilder: (context, index) {
              final link = widget.sharedLinks[index];
              final previewData = _previewDataMap[link.url];

              final subtitleText = previewData?.description ?? link.url;
              final clippedSubtitle = subtitleText.length > 80
                  ? '${subtitleText.substring(0, 77)}...'
                  : subtitleText;

              return PreviewCard(
                title: previewData?.title ?? link.platform,
                subtitle: clippedSubtitle,
                imageUrl: previewData?.image,
                width: 280,
                onTap: () {
                  Navigator.pushNamed(
                    context,
                    '/shared_link_detail',
                    arguments: link.id,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

