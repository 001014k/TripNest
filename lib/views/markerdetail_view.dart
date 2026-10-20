import '../widgets/app_photo_hero.dart';
import '../navigation/app_page_route.dart';
import '../widgets/app_overlays.dart';
import '../widgets/reference_design.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../design/app_design.dart';
import '../env.dart';
import '../viewmodels/markerdetail_viewmodel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'mapsample_view.dart';
import 'marker_info_view.dart';

// ─────────────────────────────────────────
// 메인 뷰
// ─────────────────────────────────────────
class MarkerDetailView extends StatefulWidget {
  final Marker marker;
  final String keyword;
  final Object? photoHeroTag;
  final MarkerDetailViewModel Function(Marker)? viewModelFactory;

  const MarkerDetailView({
    required this.marker,
    required this.keyword,
    this.viewModelFactory,
    this.photoHeroTag,
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
    showAppSheet<void>(
      context: ctx,
      builder: (_) => _NavigationSheet(vm: vm),
    );
  }

  // ── 빌드 ────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = widget.viewModelFactory?.call(widget.marker) ??
            MarkerDetailViewModel(widget.marker);
        vm.fetchUserMarkerDetail(widget.marker.markerId.value);
        return vm;
      },
      child: Consumer<MarkerDetailViewModel>(
        builder: (ctx, vm, _) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: Scaffold(
              backgroundColor: Colors.white,
              body: SafeArea(
                  child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          child: Row(children: [
                            IconButton(
                                tooltip: '뒤로',
                                onPressed: () => Navigator.pop(ctx),
                                icon: const Icon(Icons.arrow_back_ios_new,
                                    size: 20)),
                            const ReferenceLogo(),
                            const SizedBox(width: 10),
                            const Expanded(
                                child: Text('TripNest',
                                    style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800))),
                            IconButton(
                                tooltip: '장소 공유',
                                onPressed: () => _sharePlace(ctx, vm),
                                icon: const Icon(Icons.ios_share_outlined)),
                            IconButton(
                                tooltip: '더보기',
                                onPressed: () => _showMoreMenu(ctx, vm),
                                icon: const Icon(Icons.more_horiz)),
                          ]))),
                  SliverToBoxAdapter(
                      child: AppPhotoHero(tag: widget.photoHeroTag,
                        child: _ReferencePlaceHero(
                          vm: vm, controller: _pageController,
                          currentPage: _currentPage))),
                  SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      sliver: SliverList.list(children: [
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  child: Text(vm.title,
                                      style: const TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.8))),
                              Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: const Color(0xFFEAEAEA)),
                                      boxShadow: const [
                                        BoxShadow(
                                            color: Color(0x08000000),
                                            blurRadius: 12,
                                            offset: Offset(0, 3))
                                      ]),
                                  child: IconButton(
                                      tooltip: '저장된 리스트',
                                      onPressed: () => _showSavedLists(ctx, vm),
                                      icon:
                                          const Icon(Icons.bookmark, size: 24)))
                            ]),
                        const SizedBox(height: 9),
                        Wrap(spacing: 7, runSpacing: 5, children: [
                          _detailChip(
                              _categoryIcon(vm.keyword ?? widget.keyword),
                              vm.keyword ?? widget.keyword),
                          if (vm.address?.isNotEmpty ?? false)
                            _detailChip(Icons.place_outlined, vm.region)
                        ]),
                        if (vm.memo?.isNotEmpty ?? false) ...[
                          const SizedBox(height: 13),
                          Text(vm.memo!,
                              style: AppDesign.bodyMedium
                                  .copyWith(color: AppDesign.secondaryText))
                        ],
                        const SizedBox(height: 16),
                        Row(children: [
                          Expanded(
                              child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 42),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      foregroundColor: const Color(0xFF181818),
                                      side: const BorderSide(
                                          color: Color(0xFFE8E8EB)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14))),
                                  onPressed: () =>
                                      _showNavigationSheet(ctx, vm),
                                  icon: const Icon(Icons.near_me_outlined,
                                      size: 21),
                                  label: const Text('길찾기'))),
                          const SizedBox(width: 7),
                          Expanded(
                              child: OutlinedButton.icon(
                                  style: OutlinedButton.styleFrom(
                                      minimumSize: const Size(0, 42),
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8),
                                      foregroundColor: const Color(0xFF181818),
                                      side: const BorderSide(
                                          color: Color(0xFFE8E8EB)),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(14))),
                                  onPressed: () => _sharePlace(ctx, vm),
                                  icon: const Icon(Icons.ios_share_outlined,
                                      size: 21),
                                  label: const Text('공유'))),
                          const SizedBox(width: 7),
                          Expanded(
                              child: Container(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  decoration: BoxDecoration(
                                      color: AppDesign.borderColor,
                                      borderRadius: BorderRadius.circular(14)),
                                  child: const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.bookmark, size: 20),
                                        SizedBox(width: 4),
                                        Text('저장됨')
                                      ]))),
                        ]),
                        const SizedBox(height: 14),
                        _InfoCard(
                            vm: vm, onLists: () => _showSavedLists(ctx, vm)),
                        const SizedBox(height: 20),
                        const Text('관련 정보', style: AppDesign.headingSmall),
                        const SizedBox(height: 10),
                        if (vm.isLoadingPlaceDetails)
                          const LinearProgressIndicator(minHeight: 2),
                        if (vm.placeDetailsError != null)
                          Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Expanded(
                                    child: Text(vm.placeDetailsError!,
                                        style: AppDesign.bodySmall)),
                                TextButton(
                                    onPressed: vm.isLoadingPlaceDetails
                                        ? null
                                        : vm.retryPlaceDetails,
                                    child: const Text('재시도')),
                              ])),
                        _StatRow(vm: vm),
                        ...[const SizedBox(height: 10), _MapPreview(vm: vm)],
                        if (vm.phone != null || vm.distance != null) ...[
                          const SizedBox(height: 12),
                          ReferenceCard(
                              child: Column(children: [
                            if (vm.phone != null)
                              ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.phone_outlined),
                                  title: Text(vm.phone!),
                                  onTap: () =>
                                      launchUrl(Uri.parse('tel:${vm.phone}'))),
                            if (vm.distance != null)
                              ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.directions_walk),
                                  title: Text('현재 위치에서 ${vm.distance}'),
                                  subtitle: vm.walkTime == null
                                      ? null
                                      : Text(vm.walkTime!)),
                          ])),
                        ],
                      ])),
                ],
              ))),
        ),
      ),
    );
  }

  Widget _detailChip(IconData icon, String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
            color: AppDesign.lightGray,
            borderRadius: BorderRadius.circular(20)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 14),
          const SizedBox(width: 5),
          Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppDesign.bodySmall))
        ]),
      );

  void _showSavedLists(BuildContext context, MarkerDetailViewModel vm) {
    showAppSheet<void>(
        context: context,
        builder: (sheet) => AppSheet(
              title: '저장된 리스트',
              subtitle: '이 장소를 담아둔 여행 리스트예요.',
              children: [
                if (vm.savedLists.isEmpty)
                  const Padding(
                      padding: EdgeInsets.all(20),
                      child: Text('아직 리스트에 추가하지 않은 장소입니다.',
                          style: AppDesign.bodyMedium)),
                for (final list in vm.savedLists)
                  AppSheetOption(
                      title: list['name']!,
                      icon: Icons.format_list_bulleted,
                      onTap: () {
                        Navigator.pop(sheet);
                        Navigator.push(
                            context,
                            AppPageRoute(
                                builder: (_) => MarkerInfoPage(
                                    listId: list['id']!,
                                    listName: list['name'])));
                      }),
              ],
            ));
  }

  // ── 더보기 메뉴 ─────────────────────────
  void _showMoreMenu(BuildContext ctx, MarkerDetailViewModel vm) {
    showAppSheet<void>(
      context: ctx,
      builder: (_) => _MoreMenuSheet(
        onDelete: () async {
          Navigator.pop(ctx);
          final ok = await _confirmDelete(ctx);
          if (ok == true && ctx.mounted) {
            try {
              await vm.deleteMarker();
              if (!ctx.mounted) return;
              ScaffoldMessenger.of(ctx).showSnackBar(
                const SnackBar(content: Text('마커 및 연관 데이터가 삭제되었습니다.')),
              );
              Navigator.pushNamedAndRemoveUntil(ctx, '/map', (route) => false);
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
        builder: (_) => const AppConfirmDialog(
            title: '마커를 삭제할까요?',
            message: '마커와 연결된 데이터가 삭제됩니다. 이 작업은 되돌릴 수 없습니다.',
            confirmLabel: '삭제',
            destructive: true,
            icon: Icons.delete_outline),
      );

  Future<void> _sharePlace(
      BuildContext context, MarkerDetailViewModel vm) async {
    final position = vm.marker.position;
    final title = vm.title;
    final address = vm.address?.trim();
    final mapUrl = Uri.https(
      'www.google.com',
      '/maps/search/',
      {
        'api': '1',
        'query': '${position.latitude},${position.longitude}',
      },
    );
    final message = [
      '$title 공유',
      if (address != null && address.isNotEmpty) address,
      mapUrl.toString(),
    ].join('\n');
    final box = context.findRenderObject() as RenderBox?;

    await SharePlus.instance.share(
      ShareParams(
        text: message,
        title: title,
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }
}

// ─────────────────────────────────────────
// 히어로 슬리버 (이미지 + 정보 오버레이)
// ─────────────────────────────────────────
class _ReferencePlaceHero extends StatefulWidget {
  final MarkerDetailViewModel vm;
  final PageController controller;
  final int currentPage;
  const _ReferencePlaceHero(
      {required this.vm, required this.controller, required this.currentPage});
  @override
  State<_ReferencePlaceHero> createState() => _ReferencePlaceHeroState();
}

class _ReferencePlaceHeroState extends State<_ReferencePlaceHero> {
  late Future<List<String>> _photos;
  String _key = '';
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _load();
  }

  @override
  void didUpdateWidget(covariant _ReferencePlaceHero oldWidget) {
    super.didUpdateWidget(oldWidget);
    _load();
  }

  void _load() {
    final key = '${widget.vm.title}|${widget.vm.address}';
    if (_key == key) return;
    _key = key;
    _photos = widget.vm.fetchPhotos(widget.vm.address ?? '', widget.vm.title);
  }

  @override
  Widget build(BuildContext context) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        child: SizedBox(
            height: MediaQuery.sizeOf(context).width * 0.57,
            child: FutureBuilder<List<String>>(
                future: _photos,
                builder: (context, snapshot) {
                  final photos = snapshot.data ?? [];
                  return Stack(fit: StackFit.expand, children: [
                    if (photos.isEmpty)
                      const ColoredBox(
                          color: AppDesign.lightGray,
                          child: Icon(Icons.photo_outlined,
                              size: 40, color: AppDesign.subtleText))
                    else
                      PageView.builder(
                          controller: widget.controller,
                          itemCount: photos.length,
                          itemBuilder: (_, index) => Image.network(
                              photos[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const ColoredBox(
                                  color: AppDesign.lightGray,
                                  child: Icon(Icons.photo_outlined)))),
                    if (photos.isNotEmpty)
                      Positioned(
                          right: 16,
                          bottom: 12,
                          child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                  '${widget.currentPage + 1} / ${photos.length}',
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 11)))),
                  ]);
                })),
      );
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.vm});
  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ReferenceCard(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: IntrinsicHeight(
          child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Expanded(
            flex: 12,
            child: _StatCard(
                icon: Icons.schedule_outlined,
                label: '영업시간',
                value: vm.businessHours?.split('\n').last ?? '정보 없음',
                onTap: () => _showFullBusinessHours(context, vm))),
        const VerticalDivider(width: 1, color: Color(0xFFECECEF)),
        Expanded(
            flex: 10,
            child: _StatCard(
                icon: Icons.star_border,
                label: '평점',
                value: vm.rating?.toStringAsFixed(1) ?? '–',
                sub: vm.reviewCount == null ? null : '(${vm.reviewCount}개)',
                onTap: () => _runExternalAction(context, vm.openGoogleReview))),
        const VerticalDivider(width: 1, color: Color(0xFFECECEF)),
        Expanded(
            flex: 10,
            child: _StatCard(
                icon: Icons.person_outline,
                label: '방문자 리뷰',
                value: vm.reviewCount == null
                    ? '리뷰 정보 없음'
                    : '리뷰 ${vm.reviewCount}개',
                onTap: () => _runExternalAction(context, vm.openGoogleReview))),
      ])),
    );
  }

  void _showFullBusinessHours(BuildContext context, MarkerDetailViewModel vm) {
    if (vm.businessHours == null || vm.businessHours == '영업시간 정보 없음') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('영업시간 정보가 없습니다')),
      );
      return;
    }

    showAppSheet<void>(
      context: context,
      builder: (_) => _FullBusinessHoursSheet(vm: vm),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard(
      {required this.icon,
      required this.label,
      required this.value,
      this.sub,
      required this.onTap});
  final IconData icon;
  final String label, value;
  final String? sub;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, size: 16),
              const SizedBox(width: 5),
              Flexible(child: Text(label, style: const TextStyle(fontSize: 10)))
            ]),
            const SizedBox(height: 8),
            Text.rich(
                TextSpan(
                    text: value,
                    style: TextStyle(
                        fontSize: label == '평점' ? 16 : 11,
                        fontWeight:
                            label == '평점' ? FontWeight.w700 : FontWeight.w400),
                    children: [
                      if (sub != null)
                        TextSpan(
                            text: ' $sub',
                            style: const TextStyle(
                                fontSize: 10,
                                color: Color(0xFF86868B),
                                fontWeight: FontWeight.w400))
                    ]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ])));
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.vm, required this.onLists});
  final MarkerDetailViewModel vm;
  final VoidCallback onLists;
  @override
  Widget build(BuildContext context) => ReferenceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(children: [
        _InfoRow(
            icon: Icons.location_on_outlined,
            label: '주소',
            value: vm.address ?? '주소 정보 없음',
            onTap: () {
              if (vm.address == null) return;
              Clipboard.setData(ClipboardData(text: vm.address!));
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('주소를 복사했습니다')));
            }),
        const Divider(height: 1, color: Color(0xFFECECEF)),
        _InfoRow(
            icon: Icons.format_list_bulleted,
            label: '저장된 리스트',
            value: vm.savedLists.isEmpty
                ? '저장된 리스트 없음'
                : vm.savedLists.map((e) => e['name']).join(', '),
            onTap: onLists),
        const Divider(height: 1, color: Color(0xFFECECEF)),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(children: [
              const Icon(Icons.sell_outlined, size: 20),
              const SizedBox(width: 14),
              const Text('태그', style: TextStyle(fontSize: 13)),
              const SizedBox(width: 12),
              Expanded(
                  child: Wrap(spacing: 5, runSpacing: 5, children: [
                if (vm.tags.isEmpty)
                  const Text('등록된 태그 없음',
                      style: TextStyle(fontSize: 12, color: Color(0xFF85858B))),
                ...vm.tags.map((tag) => Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                        color: const Color(0xFFF4F4F5),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(tag, style: const TextStyle(fontSize: 11)))),
              ])),
            ])),
      ]));
}

class _MapPreview extends StatelessWidget {
  const _MapPreview({required this.vm});

  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final position = vm.marker.position;
    final staticMapUrl = _buildStaticMapUrl(position);
    return InkWell(
      onTap: () => Navigator.of(context).push(AppPageRoute(
          builder: (_) => MapPreviewView(initialMarkerId: vm.marker.markerId))),
      child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
              height: 132,
              child: Stack(fit: StackFit.expand, children: [
                Image.network(staticMapUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const ColoredBox(
                        color: Color(0xFFF0F2F0),
                        child: Icon(Icons.map_outlined, color: Colors.grey))),
                Center(
                    child: Transform.translate(
                        offset: const Offset(0, -16),
                        child: SizedBox(
                            width: 38,
                            height: 46,
                            child: CustomPaint(
                                painter: _DetailPinPainter(),
                                child: Align(
                                    alignment: const Alignment(0, -.25),
                                    child: Icon(_categoryIcon(vm.keyword),
                                        color: Colors.white, size: 20)))))),
                Positioned(
                    right: 8,
                    bottom: 12,
                    child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 9),
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(color: Color(0x14000000), blurRadius: 8)
                            ]),
                        child: const Row(children: [
                          Icon(Icons.map_outlined, size: 18),
                          SizedBox(width: 6),
                          Text('지도에서 보기',
                              style: TextStyle(
                                  fontSize: 11, fontWeight: FontWeight.w600))
                        ]))),
              ]))),
    );
  }

  String _buildStaticMapUrl(LatLng position) {
    final location =
        '${position.latitude.toStringAsFixed(6)},${position.longitude.toStringAsFixed(6)}';
    return Uri.https(
      'maps.googleapis.com',
      '/maps/api/staticmap',
      {
        'center': location,
        'zoom': '16',
        'size': '640x328',
        'scale': '2',
        'format': 'png',
        'style': 'saturation:-75|lightness:20',
        'key': Env.googleMapsApiKey,
      },
    ).toString();
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onTap});
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 20),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 3),
                  Text(value,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF77777D)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ])),
            const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Icon(Icons.chevron_right,
                    size: 19, color: Color(0xFF808088))),
          ])));
}

IconData _categoryIcon(String? category) {
  final value = category ?? '';
  if (value.contains('카페')) return Icons.coffee_outlined;
  if (value.contains('숙소')) return Icons.bed_outlined;
  if (value.contains('전시')) return Icons.image_outlined;
  if (value.contains('사진')) return Icons.photo_camera_outlined;
  if (value.contains('맛집') || value.contains('음식')) return Icons.restaurant;
  return Icons.place_outlined;
}

class _DetailPinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, size.height)
      ..cubicTo(size.width * .38, size.height * .76, 0, size.height * .65, 0,
          size.width / 2)
      ..arcToPoint(Offset(size.width, size.width / 2),
          radius: Radius.circular(size.width / 2))
      ..cubicTo(size.width, size.height * .65, size.width * .62,
          size.height * .76, size.width / 2, size.height)
      ..close();
    canvas.drawShadow(path, Colors.black.withValues(alpha: .3), 5, false);
    canvas.drawPath(path, Paint()..color = const Color(0xFF202020));
  }

  @override
  bool shouldRepaint(covariant _DetailPinPainter oldDelegate) => false;
}

// ─────────────────────────────────────────
// 전체 영업시간 BottomSheet (월~일)
// ─────────────────────────────────────────
class _FullBusinessHoursSheet extends StatelessWidget {
  const _FullBusinessHoursSheet({required this.vm});
  final MarkerDetailViewModel vm;
  @override
  Widget build(BuildContext context) => AppSheet(
        title: '영업시간',
        subtitle: vm.title,
        children: [
          for (final hours in vm.weeklyHours) _WeeklyHoursRow(hours: hours)
        ],
      );
}

class _WeeklyHoursRow extends StatelessWidget {
  const _WeeklyHoursRow({required this.hours});

  final String hours;

  @override
  Widget build(BuildContext context) {
    final lines = hours.split('\n');
    final day = lines.first;
    final time = lines.length > 1 ? lines.skip(1).join(' ') : '정보 없음';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(day,
              style: AppDesign.body15.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(
            time,
            style: AppDesign.bodyMedium.copyWith(color: AppDesign.label3),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────
// 메모 카드
// ─────────────────────────────────────────
class _MoreMenuSheet extends StatelessWidget {
  const _MoreMenuSheet({required this.onDelete});
  final VoidCallback onDelete;
  @override
  Widget build(BuildContext context) => AppSheet(
        title: '장소 관리',
        children: [
          AppSheetOption(
              title: '마커 삭제',
              subtitle: '마커와 연결된 데이터를 삭제해요.',
              icon: Icons.delete_outline,
              destructive: true,
              onTap: onDelete)
        ],
      );
}

Future<void> _runExternalAction(
  BuildContext context,
  Future<String?> Function() action,
) async {
  final error = await action();
  if (error != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }
}

class _NavigationSheet extends StatelessWidget {
  const _NavigationSheet({required this.vm});
  final MarkerDetailViewModel vm;

  @override
  Widget build(BuildContext context) {
    final apps = [
      _NavApp('구글맵', 'assets/GoogleMap.png',
          () => _runExternalAction(context, vm.openGoogleMaps)),
      _NavApp('카카오맵', 'assets/kakaomap.png',
          () => _runExternalAction(context, vm.openKakaoMap)),
      _NavApp('네이버맵', 'assets/NaverMap.png',
          () => _runExternalAction(context, vm.openNaverMap)),
      _NavApp('티맵', 'assets/Tmap.png',
          () => _runExternalAction(context, vm.openTmap)),
    ];

    return AppSheet(
      title: '어디로 안내할까요?',
      subtitle: vm.address ?? vm.title,
      children: [
        for (final app in apps)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _NavAppTile(app: app),
          )
      ],
    );
  }
}

class _NavApp {
  const _NavApp(this.name, this.asset, this.onTap);
  final String name;
  final String asset;
  final VoidCallback onTap;
}

class _NavAppTile extends StatelessWidget {
  const _NavAppTile({required this.app});
  final _NavApp app;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppDesign.lightGray,
      borderRadius: const BorderRadius.all(AppDesign.r12),
      child: InkWell(
        borderRadius: const BorderRadius.all(AppDesign.r12),
        onTap: () {
          Navigator.pop(context);
          app.onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: Image.asset(app.asset, fit: BoxFit.contain),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  app.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppDesign.label1,
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
