import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_design.dart';
import '../viewmodels/marker_info_viewmodel.dart';
import '../views/add_markers_to_list_view.dart';

class MarkerInfoPage extends StatefulWidget {
  final String listId;

  const MarkerInfoPage({Key? key, required this.listId}) : super(key: key);

  @override
  State<MarkerInfoPage> createState() => _MarkerInfoPageState();
}

class _MarkerInfoPageState extends State<MarkerInfoPage> {
  late MarkerInfoViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MarkerInfoViewModel(listId: widget.listId);
  }

  @override
  void dispose() {
    viewModel.dispose();
    super.dispose();
  }

  Future<void> navigateToAddMarkersToListPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMarkersToListPage(listId: widget.listId),
      ),
    );
    if (result == true) {
      await viewModel.loadMarkers();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<MarkerInfoViewModel>.value(
      value: viewModel,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Container(
          decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
          child: SafeArea(
            child: Consumer<MarkerInfoViewModel>(
              builder: (context, vm, child) {
                return CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(child: _buildPremiumAppBar(context)),
                    if (vm.isLoading)
                      SliverToBoxAdapter(child: _buildLoadingState())
                    else if (vm.error != null)
                      SliverToBoxAdapter(child: _buildErrorState(vm.error!))
                    else if (vm.markers.isEmpty)
                        SliverToBoxAdapter(child: _buildEmptyState())
                      else
                        SliverPadding(
                          padding: const EdgeInsets.all(24),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final marker = vm.markers[index];
                                return FutureBuilder<Map<String, String>>(
                                  future: vm.fetchMarkerDetail(marker.id),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return const Padding(
                                        padding: EdgeInsets.symmetric(vertical: 32),
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
                                          ),
                                        ),
                                      );
                                    }
                                    return _MarkerInfoCard(
                                      details: snapshot.data!,
                                      onDelete: () => _confirmDelete(context, vm, marker.id),
                                    );
                                  },
                                );
                              },
                              childCount: vm.markers.length,
                            ),
                          ),
                        ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                );
              },
            ),
          ),
        ),
        floatingActionButton: _buildPremiumFAB(),
      ),
    );
  }

  Widget _buildPremiumAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppDesign.softShadow,
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/list',
                        (route) => false,
                  );
                },
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: AppDesign.primaryText,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          const Text('마커 정보', style: AppDesign.headingLarge),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: AppDesign.primaryGradient,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),
          Text(
            '마커를 불러오는 중...',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: Colors.red.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 40,
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),
          Text(
            '오류가 발생했습니다',
            style: AppDesign.headingMedium.copyWith(color: Colors.red),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            error,
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.elevatedShadow,
      ),
      child: Column(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.add_location_alt,
              color: Colors.white,
              size: 48,
            ),
          ),
          const SizedBox(height: AppDesign.spacing24),
          Text(
            '마커가 없습니다.\n새로운 마커를 추가해보세요!',
            style: AppDesign.headingMedium.copyWith(
              color: Colors.white,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            '여행지의 위치를 마커로 저장해보세요',
            style: AppDesign.bodyMedium.copyWith(
              color: Colors.white.withOpacity(0.9),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumFAB() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppDesign.glowShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: navigateToAddMarkersToListPage,
          child: const Icon(
            Icons.add_location,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, MarkerInfoViewModel vm, String markerId) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
          contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          title: const Text(
            '삭제하시겠습니까?',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          content: const Text(
            '이 마커를 삭제하면 되돌릴 수 없습니다.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('삭제'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: AppDesign.primaryText,
              ),
              child: const Text('취소'),
            ),
          ],
        );
      },
    );
    if (result == true) {
      vm.deleteMarker(markerId);
    }
  }
}

// 마커 카드 위젯
class _MarkerInfoCard extends StatelessWidget {
  final Map<String, String> details;
  final VoidCallback onDelete;

  const _MarkerInfoCard({
    required this.details,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final title = details['title'] ?? '제목 없음';
    final address = details['address'] ?? '주소 없음';
    final keyword = details['keyword'] ?? '키워드 없음';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
        border: Border.all(
          color: AppDesign.borderColor,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppDesign.primaryGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: AppDesign.softShadow,
              ),
              child: const Icon(
                Icons.place,
                color: Colors.white,
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
                    style: AppDesign.headingSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppDesign.spacing8),
                  Row(
                    children: [
                      const Icon(Icons.location_city, size: 16, color: AppDesign.travelBlue),
                      const SizedBox(width: AppDesign.spacing4),
                      Expanded(
                        child: Text(
                          address,
                          style: AppDesign.bodyMedium.copyWith(
                            color: AppDesign.secondaryText,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDesign.spacing4),
                  Row(
                    children: [
                      const Icon(Icons.label_outline, size: 16, color: AppDesign.travelPurple),
                      const SizedBox(width: AppDesign.spacing4),
                      Text(
                        keyword,
                        style: AppDesign.bodyMedium.copyWith(
                          color: AppDesign.subtleText,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppDesign.spacing8),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppDesign.lightGray,
                borderRadius: BorderRadius.circular(10),
              ),
              child: IconButton(
                icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 20),
                onPressed: onDelete,
              ),
            ),
          ],
        ),
      ),
    );
  }
}