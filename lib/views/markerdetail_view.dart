import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../viewmodels/markerdetail_viewmodel.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../design/app_design.dart';
import 'mapsample_view.dart';

class MarkerDetailView extends StatefulWidget {
  final Marker marker;
  final String keyword;

  MarkerDetailView({
    required this.marker,
    required this.keyword,
  });

  @override
  _MarkerDetailPageState createState() => _MarkerDetailPageState();
}

class _MarkerDetailPageState extends State<MarkerDetailView> {


  @override
  void initState() {
    super.initState();
  }

  void _showBottomSheet(BuildContext context, MarkerDetailViewModel viewmodel) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '길찾기',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _mapButtonWithImage('구글맵', 'assets/GoogleMap.png', () => viewmodel.openGoogleMaps(context)),
              const Divider(),
              _mapButtonWithImage('카카오맵', 'assets/kakaomap.png', () => viewmodel.openKakaoMap(context)),
              const Divider(),
              _mapButtonWithImage('네이버맵', 'assets/NaverMap.png', () => viewmodel.openNaverMap(context)),
              const Divider(),
              _mapButtonWithImage('티맵', 'assets/Tmap.png', () => viewmodel.openTmap(context)),
            ],
          ),
        );
      },
    );
  }


  Widget _mapButtonWithImage(String title, String assetPath, VoidCallback onTap, {Color? color}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: color == null ? AppDesign.primaryGradient : null,
        color: color,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(assetPath, height: 22, width: 22), // <- 이미지 아이콘
              const SizedBox(width: AppDesign.spacing8),
              Text(
                title,
                style: AppDesign.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = MarkerDetailViewModel(widget.marker);
        vm.fetchUserMarkerDetail(widget.marker.markerId.value);
        return vm;
      },
      child: Consumer<MarkerDetailViewModel>(
        builder: (context, viewmodel, _) {
          return Scaffold(
            backgroundColor: Colors.transparent,
            body: Container(
              decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDesign.spacing24),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          AppDesign.spacing24 * 2, // 위아래 패딩 고려
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildPremiumAppBar(context),
                          const SizedBox(height: AppDesign.spacing24),
                          _buildMarkerInfoCard(viewmodel),
                          const SizedBox(height: AppDesign.spacing24),
                          if (viewmodel.address != null)
                            _buildAddressCard(viewmodel.address!),
                          const SizedBox(height: AppDesign.spacing24),
                          _buildReviewCards(viewmodel),
                          const SizedBox(height: AppDesign.spacing24),
                          _buildActionButtons(context, viewmodel),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context) {
    return Row(
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
              onTap: () => Navigator.of(context).pop(),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppDesign.primaryText,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppDesign.spacing16),
        const Text('마커 정보', style: AppDesign.headingLarge),
      ],
    );
  }

  Widget _buildMarkerInfoCard(MarkerDetailViewModel vm) {
    return Container(
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      padding: const EdgeInsets.all(AppDesign.spacing24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppDesign.softShadow,
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 28),
              ),
              const SizedBox(width: AppDesign.spacing16),
              Expanded(
                child: Text(
                  vm.title ?? '제목 없음',
                  style: AppDesign.headingMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Builder(
                builder: (popupContext) {
                  return PopupMenuButton<String>(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    onSelected: (value) async {
                      if (value == '삭제') {
                        try {
                          final viewModel = popupContext.read<MarkerDetailViewModel>();
                          await viewModel.deleteMarker(popupContext);
                        } catch (e) {
                          ScaffoldMessenger.of(popupContext).showSnackBar(
                            SnackBar(content: Text('삭제 실패: $e')),
                          );
                        }
                      } else if (value == '수정') {
                        // 수정 기능 구현
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: '수정', child: Text('수정')),
                      const PopupMenuItem(value: '삭제', child: Text('삭제')),
                    ],
                    icon: const Icon(Icons.more_vert, color: AppDesign.subtleText),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing16),
          Row(
            children: [
              const Icon(Icons.label_outline, size: 18, color: AppDesign.travelPurple),
              const SizedBox(width: AppDesign.spacing8),
              Text(
                vm.keyword ?? '키워드 없음',
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.travelPurple,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddressCard(String address) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
      ),
      padding: const EdgeInsets.all(AppDesign.spacing20),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: AppDesign.travelBlue, size: 22),
          const SizedBox(width: AppDesign.spacing8),
          Expanded(
            child: Text(
              address,
              style: AppDesign.bodyLarge,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCards(MarkerDetailViewModel vm) {
    final reviewLinks = vm.reviewLinks;
    if (reviewLinks.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("🔍 리뷰 미리보기", style: AppDesign.headingSmall),
        const SizedBox(height: AppDesign.spacing8),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: reviewLinks.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppDesign.spacing12),
            itemBuilder: (context, index) {
              final review = reviewLinks[index];



              return GestureDetector(
                onTap: () async {
                  final url = Uri.parse(review['url']!);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  }
                },
                child: Container(
                  width: 180,
                  decoration: BoxDecoration(
                    color: AppDesign.lightGray,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    boxShadow: AppDesign.softShadow,
                  ),
                  padding: const EdgeInsets.all(AppDesign.spacing16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Image.asset(review['icon']!, height: 28),
                      SizedBox(height: 8),
                      Text('${review['platform']} 리뷰', style: TextStyle(
                          fontSize: 14)),
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

  Widget _buildActionButtons(BuildContext context, MarkerDetailViewModel vm) {
    return Row(
      children: [
        Expanded(
          child: _mapButton(
            '지도에서 보기',
            Icons.map,
                () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MapSampleView(
                    initialMarkerId: vm.marker.markerId, // markerId를 전달
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: AppDesign.spacing16),
        Expanded(
          child: _mapButton(
            '길찾기',
            Icons.directions,
                () => _showBottomSheet(context, vm),
            color: AppDesign.travelOrange,
          )
        ),
      ],
    );
  }

  Widget _mapButton(String title, IconData icon, VoidCallback onTap, {Color? color}) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        gradient: color == null ? AppDesign.primaryGradient : null,
        color: color,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.softShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 22),
              const SizedBox(width: AppDesign.spacing8),
              Text(
                title,
                style: AppDesign.bodyMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}