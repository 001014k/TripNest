import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../env.dart';
import '../design/app_design.dart';
import '../viewmodels/markerdetail_viewmodel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'mapsample_view.dart';

// ─────────────────────────────────────────
// 메인 뷰
// ─────────────────────────────────────────
class MarkerDetailView extends StatefulWidget {
  final Marker marker;
  final String keyword;

  const MarkerDetailView({
    required this.marker,
    required this.keyword,
    super.key,
  });

  @override
  State<MarkerDetailView> createState() => _MarkerDetailViewState();
}

class _MarkerDetailViewState extends State<MarkerDetailView> {
  late final PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      final p = _pageController.page?.round() ?? 0;
      if (p != _currentPage) setState(() => _currentPage = p);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── 길찾기 바텀시트 ──────────────────────
  void _showNavigationSheet(BuildContext ctx, MarkerDetailViewModel vm) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _NavigationSheet(vm: vm),
    );
  }

  // ── 빌드 ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = MarkerDetailViewModel(widget.marker);
        vm.fetchUserMarkerDetail(widget.marker.markerId.value);
        return vm;
      },
      child: Consumer<MarkerDetailViewModel>(
        builder: (ctx, vm, _) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: AppDesign.bg,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                // ── 스크롤 영역 ──
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _HeroSliver(
                      vm: vm,
                      pageController: _pageController,
                      currentPage: _currentPage,
                      onBack: () => Navigator.of(ctx).pop(),
                      onMore: () => _showMoreMenu(ctx, vm),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          _StatRow(vm: vm),
                          const SizedBox(height: 12),
                          _InfoCard(vm: vm),
                          const SizedBox(height: 12),
                          _ReviewSection(vm: vm),
                          if (vm.memo != null && vm.memo!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _MemoCard(memo: vm.memo!),
                          ],
                          const SizedBox(height: 104), // bottom bar 여백
                        ]),
                      ),
                    ),
                  ],
                ),

                // ── 하단 고정 바 ──
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: _BottomBar(
                    onNavigate: () => _showNavigationSheet(ctx, vm),
                    onMap: () => Navigator.push(
                      ctx,
                      MaterialPageRoute(
                        builder: (_) => MapSampleView(
                          initialMarkerId: vm.marker.markerId,
                        ),
                      ),
                    ),
                    onShare: () => vm.saveMarker(ctx),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── 더보기 메뉴 ─────────────────────────
  void _showMoreMenu(BuildContext ctx, MarkerDetailViewModel vm) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (_) => _MoreMenuSheet(
        onEdit: () {
          Navigator.pop(ctx);
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('수정 기능은 곧 추가될 예정입니다')),
          );
        },
        onDelete: () async {
          Navigator.pop(ctx);
          final ok = await _confirmDelete(ctx);
          if (ok == true && ctx.mounted) {
            try {
              await vm.deleteMarker(ctx);
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text('삭제 실패: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          }
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext ctx) => showDialog<bool>(
    context: ctx,
    builder: (d) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('마커 삭제'),
      content: const Text('정말 이 마커를 삭제하시겠습니까?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(d, false),
          child: const Text('취소'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(d, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('삭제'),
        ),
      ],
    ),
  );
}

// ─────────────────────────────────────────
// 히어로 슬리버 (이미지 + 정보 오버레이)
// ─────────────────────────────────────────
class _HeroSliver extends StatelessWidget {
  const _HeroSliver({
    required this.vm,
    required this.pageController,
    required this.currentPage,
    required this.onBack,
    required this.onMore,
  });

  final MarkerDetailViewModel vm;
  final PageController pageController;
  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: false,
      stretch: true,
      automaticallyImplyLeading: false,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: _HeroContent(
          vm: vm,
          pageController: pageController,
          currentPage: currentPage,
          onBack: onBack,
          onMore: onMore,
        ),
      ),
    );
  }
}

class _HeroContent extends StatelessWidget {
  const _HeroContent({
    required this.vm,
    required this.pageController,
    required this.currentPage,
    required this.onBack,
    required this.onMore,
  });

  final MarkerDetailViewModel vm;
  final PageController pageController;
  final int currentPage;
  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: vm.fetchPhotos(vm.address ?? '', vm.title),
      builder: (ctx, snap) {
        final photos = snap.data ?? [];

        // ── 수정된 _HeroContent build 메서드 내 Stack ──
        return Stack(
          fit: StackFit.expand,
          children: [
            // 1. PageView (가장 아래, 제스처 우선)
            photos.isEmpty
                ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                ),
              ),
            )
                : PageView.builder(
              controller: pageController,
              itemCount: photos.length,
              physics: const ClampingScrollPhysics(), // ← BouncingScrollPhysics에서 변경
              itemBuilder: (_, i) => CachedNetworkImage(
                imageUrl: photos[i],
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(color: const Color(0xFF4F46E5)),
                errorWidget: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF9333EA)],
                    ),
                  ),
                ),
              ),
            ),

            // 2. 그라디언트 오버레이 — IgnorePointer로 터치 완전 차단
            IgnorePointer(
              child: const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x26000000), Color(0x00000000), Color(0x8C000000)],
                    stops: [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),

            // 3. 상단 버튼 — 버튼 영역만 터치 허용
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _GlassButton(
                    onTap: onBack,
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
                  ),
                  Row(
                    children: [
                      if (photos.length > 1)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${currentPage + 1} / ${photos.length}',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                          ),
                        ),
                      const SizedBox(width: 8),
                      _GlassButton(
                        onTap: onMore,
                        child: const Icon(Icons.more_horiz, color: Colors.white, size: 20),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // 4. 페이지 도트 — IgnorePointer
            if (photos.length > 1)
              Positioned(
                bottom: 72,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(photos.length, (i) {
                      final active = i == currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? Colors.white : Colors.white54,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                ),
              ),

            // 5. 하단 제목/주소 오버레이 — IgnorePointer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.label, size: 12, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(
                              vm.keyword ?? '카테고리',
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        vm.title ?? '이름 없음',
                        style: AppDesign.title22,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      if (vm.address != null)
                        Row(
                          children: [
                            const Icon(Icons.location_on, size: 13, color: Colors.white70),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                vm.address!,
                                style: const TextStyle(fontSize: 13, color: Colors.white70),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// 통계 행 (영업시간 · 평점 · 거리)
// ─────────────────────────────────────────
class _StatRow extends StatelessWidget {
  const _StatRow({required this.vm});
  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _StatCard(
          label: '영업시간',
          value: vm.businessHours ?? '–',
          sub: vm.isOpen == true ? '영업 중' : vm.isOpen == false ? '영업 종료' : null,
          subColor: vm.isOpen == true ? AppDesign.success : AppDesign.label3,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: '평점',
          value: vm.rating != null ? '★ ${vm.rating}' : '–',
          sub: vm.reviewCount != null ? '리뷰 ${vm.reviewCount}개' : null,
        ),
        const SizedBox(width: 10),
        _StatCard(
          label: '거리',
          value: vm.distance ?? '–',
          sub: vm.walkTime,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });

  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: const BorderRadius.all(AppDesign.r14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(label, style: AppDesign.caption11),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w600,
                color: AppDesign.label1,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (sub != null) ...[
              const SizedBox(height: 2),
              Text(
                sub!,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w500,
                  color: subColor ?? AppDesign.label3,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 정보 카드 (주소 · 전화)
// ─────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.vm});
  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: const BorderRadius.all(AppDesign.r16),
      ),
      child: Column(
        children: [
          if (vm.address != null)
            _InfoRow(
              icon: Icons.location_on_rounded,
              iconColor: const Color(0xFF4F46E5),
              iconBg: const Color(0xFFEEF2FF),
              label: '주소',
              value: vm.address!,
              onTap: null,
              showChevron: false,
            ),
          if (vm.address != null && vm.phone != null)
            const Divider(height: 0, indent: 60, color: AppDesign.separator),
          if (vm.phone != null)
            _InfoRow(
              icon: Icons.phone_rounded,
              iconColor: const Color(0xFF22C55E),
              iconBg: const Color(0xFFF0FDF4),
              label: '전화번호',
              value: vm.phone!,
              valueColor: AppDesign.primary,
              onTap: () => launchUrl(Uri.parse('tel:${vm.phone}')),
              showChevron: true,
            ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.value,
    this.valueColor,
    required this.onTap,
    required this.showChevron,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(AppDesign.r16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppDesign.caption11),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: AppDesign.body15.copyWith(color: valueColor),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (showChevron)
              const Icon(Icons.chevron_right_rounded,
                  color: AppDesign.separator, size: 20),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 리뷰 섹션 (가로 스크롤 칩)
// ─────────────────────────────────────────
class _ReviewSection extends StatelessWidget {
  const _ReviewSection({required this.vm});
  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final links = vm.reviewLinks;
    if (links.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('리뷰 보기', style: AppDesign.caption11),
        ),
        SizedBox(
          height: 68,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: links.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (ctx, i) {
              final r = links[i];
              final url = r['url'] as String?;
              final name = r['platform'] as String?;

              if (url == null || name == null) return const SizedBox.shrink();

              // 플랫폼별 임시 아이콘 매핑
              IconData iconData;
              Color iconColor;

              switch (name) {
                case '네이버':
                  iconData = Icons.search_rounded;        // 네이버 검색 느낌
                  iconColor = const Color(0xFF03C75A);    // 네이버 그린
                  break;
                case '카카오맵':
                  iconData = Icons.map_rounded;
                  iconColor = const Color(0xFFFFCD00);    // 카카오 노랑
                  break;
                case '구글':
                  iconData = Icons.language_rounded;      // 구글 느낌
                  iconColor = const Color(0xFF4285F4);    // 구글 블루
                  break;
                case '인스타그램':
                  iconData = Icons.camera_alt_rounded;
                  iconColor = const Color(0xFFE4405F);    // 인스타 핑크
                  break;
                default:
                  iconData = Icons.map_outlined;
                  iconColor = AppDesign.primary;
              }

              return GestureDetector(
                onTap: () async {
                  final uri = Uri.parse(url);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppDesign.cardBg,
                    borderRadius: const BorderRadius.all(AppDesign.r40),
                    border: Border.all(color: AppDesign.separator, width: 0.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: iconColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Icon(iconData, size: 18, color: iconColor),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppDesign.label1,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// 메모 카드
// ─────────────────────────────────────────
class _MemoCard extends StatelessWidget {
  const _MemoCard({required this.memo});
  final String memo;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text('메모', style: AppDesign.caption11),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppDesign.cardBg,
            borderRadius: const BorderRadius.all(AppDesign.r16),
          ),
          child: Text(
            memo,
            style: const TextStyle(
              fontSize: 14, color: AppDesign.label2, height: 1.6,
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────
// 하단 고정 바
// ─────────────────────────────────────────
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.onNavigate,
    required this.onMap,
    required this.onShare,
  });

  final VoidCallback onNavigate;
  final VoidCallback onMap;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.bg.withOpacity(0.92),
        border: const Border(
          top: BorderSide(color: Color(0x14000000), width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: Row(
        children: [
          // 메인 길찾기 버튼
          Expanded(
            child: GestureDetector(
              onTap: onNavigate,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: AppDesign.primary,
                  borderRadius: const BorderRadius.all(AppDesign.r14),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.directions_rounded,
                        color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '길찾기',
                      style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // 지도 버튼
          _IconBtn(icon: Icons.map_outlined, onTap: onMap),
          const SizedBox(width: 10),
          // 공유 버튼
          _IconBtn(icon: Icons.share_outlined, onTap: onShare),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 50, height: 50,
        decoration: BoxDecoration(
          color: AppDesign.cardBg,
          borderRadius: const BorderRadius.all(AppDesign.r14),
          border: Border.all(color: AppDesign.separator, width: 0.5),
        ),
        child: Icon(icon, color: AppDesign.primary, size: 22),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 글래스 버튼 (히어로 상단)
// ─────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  const _GlassButton({required this.child, required this.onTap});
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.25),
          shape: BoxShape.circle,
        ),
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────
// 더보기 바텀시트
// ─────────────────────────────────────────
class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet({required this.onEdit, required this.onDelete});
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: const BorderRadius.all(AppDesign.r16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetItem(
            icon: Icons.edit_outlined,
            label: '수정',
            color: AppDesign.primary,
            onTap: onEdit,
          ),
          const Divider(height: 0, color: AppDesign.separator),
          _SheetItem(
            icon: Icons.delete_outline_rounded,
            label: '삭제',
            color: Colors.red,
            onTap: onDelete,
          ),
          const SizedBox(height: 8),
          Container(height: 0.5, color: AppDesign.separator),
          _SheetItem(
            icon: Icons.close,
            label: '취소',
            color: AppDesign.label3,
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  const _SheetItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.all(AppDesign.r16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w500, color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// 길찾기 앱 선택 바텀시트
// ─────────────────────────────────────────
class _NavigationSheet extends StatelessWidget {
  const _NavigationSheet({required this.vm});
  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final apps = [
      _NavApp('구글맵', 'assets/GoogleMap.png', () => vm.openGoogleMaps(context)),
      _NavApp('카카오맵', 'assets/kakaomap.png', () => vm.openKakaoMap(context)),
      _NavApp('네이버맵', 'assets/NaverMap.png', () => vm.openNaverMap(context)),
      _NavApp('티맵',    'assets/Tmap.png',      () => vm.openTmap(context)),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: const BorderRadius.all(AppDesign.r16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: AppDesign.separator,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.directions_rounded,
                      color: AppDesign.primary, size: 20),
                ),
                const SizedBox(width: 12),
                const Text(
                  '길찾기 앱 선택',
                  style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w600,
                    color: AppDesign.label1,
                  ),
                ),
              ],
            ),
          ),
          ...apps.map((app) => _NavAppRow(app: app)),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _NavApp {
  const _NavApp(this.name, this.asset, this.onTap);
  final String name;
  final String asset;
  final VoidCallback onTap;
}

class _NavAppRow extends StatelessWidget {
  const _NavAppRow({required this.app});
  final _NavApp app;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Divider(height: 0, indent: 68, color: AppDesign.separator),
        InkWell(
          onTap: () {
            Navigator.pop(context);
            app.onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 36, height: 36,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F2F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Image.asset(app.asset, fit: BoxFit.contain),
                ),
                const SizedBox(width: 14),
                Text(
                  app.name,
                  style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w500,
                    color: AppDesign.label1,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right_rounded,
                    color: AppDesign.separator, size: 20),
              ],
            ),
          ),
        ),
      ],
    );
  }
}