import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_design.dart';
import '../viewmodels/marker_list_screen_viewmodel.dart';

class MarkerListScreen extends StatefulWidget {
  @override
  State<MarkerListScreen> createState() => _MarkerListScreenState();
}

class _MarkerListScreenState extends State<MarkerListScreen> {
  @override
  void initState() {
    super.initState();
    // 위젯이 생성되자마자 fetchMarkers 실행
    Future.microtask(() {
      context.read<MarkerListViewModel>().fetchMarkers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      appBar: AppBar(
        title: const Text('저장한 장소'),
        backgroundColor: AppDesign.primaryBg,
        elevation: 0,
      ),
      body: Consumer<MarkerListViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.markers.isEmpty) {
            return const Center(child: Text('저장된 장소가 없습니다.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            itemCount: vm.markers.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppDesign.spacing12),
            itemBuilder: (context, index) {
              final marker = vm.markers[index];
              return Container(
                padding: const EdgeInsets.all(AppDesign.spacing16),
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  boxShadow: AppDesign.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(marker['title'] ?? '제목 없음', style: AppDesign.headingSmall),
                    const SizedBox(height: 4),
                    Text(marker['address'] ?? '주소 없음', style: AppDesign.bodyMedium),
                    const SizedBox(height: 4),
                    Text(marker['keyword'] ?? '', style: AppDesign.caption),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
