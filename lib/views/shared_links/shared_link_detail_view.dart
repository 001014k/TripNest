import '../../navigation/app_page_route.dart';
import '../../widgets/common/app_overlays.dart';
import '../../widgets/common/reference_design.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../design/app_design.dart';
import '../../models/shared_links/link_preview_data.dart';
import '../../models/shared_links/shared_link_model.dart';
import '../../viewmodels/map/mapsample_viewmodel.dart';
import '../../viewmodels/shared_links/shared_link_detail_viewmodel.dart';
import '../markers/markercreationscreen_view.dart';

class SharedLinkDetailView extends StatefulWidget {
  const SharedLinkDetailView({required this.link, super.key});

  final SharedLinkModel link;

  @override
  State<SharedLinkDetailView> createState() => _SharedLinkDetailViewState();
}

class _SharedLinkDetailViewState extends State<SharedLinkDetailView> {
  late final SharedLinkDetailViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SharedLinkDetailViewModel(widget.link);
    _viewModel.load();
    _viewModel.loadPlaces();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, _) => _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final link = widget.link;
    final placesWithAddress = _viewModel.places
        .where((place) => place.placeAddress?.trim().isNotEmpty ?? false)
        .toList();

    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      bottomNavigationBar: SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                      backgroundColor: AppDesign.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16))),
                  onPressed: _viewModel.isAdding || placesWithAddress.isEmpty
                      ? null
                      : () => _choosePlaceToSave(placesWithAddress),
                  icon: const Icon(Icons.format_list_bulleted),
                  label: const Text('리스트에 저장')))),
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: _SharedPlaceHeader(
                  placeCount: _viewModel.isLoadingPlaces
                      ? null
                      : placesWithAddress.length,
                  onBack: () => Navigator.of(context).pop(),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
                sliver: SliverToBoxAdapter(
                  child: _OriginalPreviewCard(
                    preview: _viewModel.preview,
                    link: link,
                    onTap: _openOriginalPost,
                  ),
                ),
              ),
              SliverToBoxAdapter(
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 28, 20, 14),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('추출된 장소',
                                style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.6)),
                            const SizedBox(height: 7),
                            Text(
                                _viewModel.isLoadingPlaces
                                    ? '링크에서 장소를 확인하고 있어요.'
                                    : '링크에서 발견한 장소 ${placesWithAddress.length}곳을 확인해보세요.',
                                style: AppDesign.bodySmall),
                          ]))),
              if (!_viewModel.isLoadingPlaces &&
                  _viewModel.placeLoadFailed &&
                  placesWithAddress.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                  sliver: SliverToBoxAdapter(
                    child: Material(
                      color: AppDesign.secondaryBg,
                      borderRadius:
                          BorderRadius.circular(AppDesign.radiusSmall),
                      child: Padding(
                        padding: const EdgeInsets.all(AppDesign.spacing12),
                        child: Row(
                          children: [
                            const Expanded(child: Text('일부 장소 정보를 불러오지 못했어요.')),
                            TextButton(
                              onPressed: _viewModel.loadPlaces,
                              child: const Text('다시 시도'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              if (_viewModel.isLoadingPlaces)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: AppDesign.spacing48),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                )
              else if (placesWithAddress.isEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverToBoxAdapter(
                    child: _MissingPlaceCard(
                      loadFailed: _viewModel.placeLoadFailed,
                      onRetry: _viewModel.loadPlaces,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  sliver: SliverList.separated(
                    itemCount: placesWithAddress.length,
                    itemBuilder: (context, index) {
                      final place = placesWithAddress[index];
                      return _ExtractedPlaceCard(
                        key: ValueKey(
                            place.id ?? '${place.url}-${place.placeAddress}'),
                        place: place,
                        isAdding: _viewModel.isAdding,
                        isChecking: _viewModel.isCheckingSavedMarkers,
                        lookupFailed: _viewModel.savedMarkerLookupFailed,
                        isSaved: _viewModel.isSaved(place),
                        rating: _viewModel.ratingFor(place),
                        onAddToMap: () => _openMarkerCreation(place),
                        onRetry: _viewModel.refreshSavedMarkers,
                      );
                    },
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDesign.spacing16),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _choosePlaceToSave(List<SharedLinkModel> places) async {
    final selected = await showAppSheet<SharedLinkModel>(
      context: context,
      builder: (sheet) => AppSheet(
        title: '저장할 장소 선택',
        subtitle: '이미 저장한 장소는 체크 표시로 알려드려요.',
        children: [
          for (final place in places)
            AppSheetOption(
              title: place.placeTitle ?? '장소',
              subtitle: place.placeAddress,
              icon: Icons.place_outlined,
              selected: _viewModel.isSaved(place),
              onTap: () => Navigator.pop(sheet, place),
            )
        ],
      ),
    );
    if (selected == null || !mounted) return;
    if (_viewModel.isSaved(selected)) {
      Navigator.pushNamed(context, '/list');
    } else {
      await _openMarkerCreation(selected);
    }
  }

  Future<void> _openOriginalPost() async {
    final uri = Uri.tryParse(widget.link.url);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openMarkerCreation(SharedLinkModel link) async {
    final address = link.placeAddress;
    if (address == null ||
        address.isEmpty ||
        _viewModel.isSaved(link) ||
        _viewModel.isAdding) {
      return;
    }

    _viewModel.setAdding(true);
    try {
      final position = await _viewModel.resolvePosition(link);
      if (!mounted) return;
      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('주소 위치를 찾지 못했습니다.')),
        );
        return;
      }
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        AppPageRoute(motion: AppMotion.editor,
          builder: (_) => MarkerCreationScreen(
            initialLatLng: position,
            initialTitle: link.placeTitle,
            initialAddress: address,
          ),
        ),
      );
      if (!mounted || result == null) return;

      final keyword = result['keyword'] as String?;
      final title = result['title'] as String?;
      if (keyword == null || title == null || title.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마커 정보를 확인할 수 없습니다.')),
        );
        return;
      }

      final saved = await context.read<MapSampleViewModel>().addMarker(
            title: title,
            snippet: result['snippet'] as String?,
            position: position,
            keyword: keyword,
            address: result['address'] as String? ?? address,
            listId: result['listId'] as String?,
            onTapCallback: (_) {},
          );
      if (!mounted) return;
      if (saved) {
        _viewModel.markSaved(link);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('내 지도에 마커를 저장했습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마커를 저장하지 못했습니다. 다시 시도해주세요.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('마커를 저장하지 못했습니다. 다시 시도해주세요.')),
        );
      }
      debugPrint('공유 장소 마커 저장 실패: $error');
    } finally {
      _viewModel.setAdding(false);
    }
  }
}

class _OriginalPreviewCard extends StatelessWidget {
  const _OriginalPreviewCard(
      {required this.preview, required this.link, required this.onTap});
  final LinkPreviewData? preview;
  final SharedLinkModel link;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: const BorderSide(color: AppDesign.borderColor)),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                        width: 86,
                        height: 104,
                        child: preview?.image != null
                            ? Image.network(preview!.image!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(
                                    Icons.link,
                                    color: AppDesign.secondaryText))
                            : const ColoredBox(
                                color: AppDesign.lightGray,
                                child: Icon(Icons.link)))),
                const SizedBox(width: 14),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      ReferencePlatform(platform: link.platform),
                      const SizedBox(height: 5),
                      Text(Uri.tryParse(link.url)?.host ?? link.url,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppDesign.caption),
                      const SizedBox(height: 10),
                      Text(preview?.title ?? link.placeTitle ?? '원본 링크 보기',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppDesign.bodyMedium),
                      if (preview?.description?.isNotEmpty ?? false)
                        Text(preview!.description!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppDesign.caption),
                    ])),
                const SizedBox(width: 8),
                const Icon(Icons.open_in_new_rounded,
                    size: 18, color: AppDesign.secondaryText),
              ])),
        ),
      );
}

class _SharedPlaceHeader extends StatelessWidget {
  const _SharedPlaceHeader({required this.placeCount, required this.onBack});
  final int? placeCount;
  final VoidCallback onBack;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        TripNestHeader(onBack: onBack),
        const SizedBox(height: 18),
        const Text('링크 상세',
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.8)),
      ]));
}

class _ExtractedPlaceCard extends StatelessWidget {
  const _ExtractedPlaceCard({
    required this.place,
    required this.isAdding,
    required this.isChecking,
    required this.lookupFailed,
    required this.isSaved,
    required this.rating,
    required this.onAddToMap,
    required this.onRetry,
    super.key,
  });

  final SharedLinkModel place;
  final bool isAdding;
  final bool isChecking;
  final bool lookupFailed;
  final bool isSaved;
  final PlaceRating? rating;
  final VoidCallback onAddToMap;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final savedTitle = place.placeTitle?.trim() ?? '';
    final title = savedTitle.isNotEmpty ? savedTitle : '이름을 확인할 수 없는 장소';
    final address = place.placeAddress!;

    return ReferenceCard(
        padding: const EdgeInsets.all(9),
        child: Row(children: [
          ReferencePhoto(
              title: title, address: address, width: 102, height: 104),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.place_outlined,
                      size: 15, color: AppDesign.secondaryText),
                  const SizedBox(width: 4),
                  Expanded(
                      child: Text(address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppDesign.bodySmall))
                ]),
                const SizedBox(height: 8),
                _PlaceRatingBadge(rating: rating),
              ])),
          const SizedBox(width: 8),
          SizedBox(
              width: 49,
              child: OutlinedButton(
                onPressed: isAdding || isChecking || isSaved
                    ? null
                    : lookupFailed
                        ? onRetry
                        : onAddToMap,
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13)),
                    side: const BorderSide(color: AppDesign.borderColor)),
                child: Column(children: [
                  if (isAdding || isChecking)
                    const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                  else
                    Icon(
                        isSaved
                            ? Icons.bookmark
                            : lookupFailed
                                ? Icons.refresh
                                : Icons.bookmark_border,
                        size: 23,
                        color: AppDesign.primaryText),
                  const SizedBox(height: 5),
                  Text(
                      isSaved
                          ? '저장됨'
                          : lookupFailed
                              ? '재시도'
                              : '저장',
                      style: const TextStyle(
                          fontSize: 11, color: AppDesign.primaryText)),
                ]),
              )),
        ]));
  }
}

class _PlaceRatingBadge extends StatelessWidget {
  const _PlaceRatingBadge({required this.rating});

  final PlaceRating? rating;

  @override
  Widget build(BuildContext context) {
    if (rating == null) return const SizedBox.shrink();

    final countLabel = rating!.count == null ? '' : ' (${rating!.count})';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppDesign.secondaryBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded,
              color: AppDesign.travelOrange, size: 16),
          const SizedBox(width: 2),
          Text(
            '${rating!.score.toStringAsFixed(1)}$countLabel',
            style: AppDesign.caption.copyWith(
              color: AppDesign.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MissingPlaceCard extends StatelessWidget {
  const _MissingPlaceCard({required this.loadFailed, required this.onRetry});

  final bool loadFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loadFailed ? '장소 정보를 불러오지 못했어요.' : '주소가 확인된 장소가 없어요.',
            style:
                AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
          ),
          if (loadFailed) ...[
            const SizedBox(height: AppDesign.spacing12),
            TextButton(onPressed: onRetry, child: const Text('다시 시도')),
          ],
        ],
      ),
    );
  }
}
