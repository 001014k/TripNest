import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../design/app_design.dart';
import '../viewmodels/marker_list_screen_viewmodel.dart';
import '../views/markerdetail_view.dart';
import '../models/marker_model.dart';

class MarkerListScreen extends StatefulWidget {
  @override
  State<MarkerListScreen> createState() => _MarkerListScreenState();
}

class _MarkerListScreenState extends State<MarkerListScreen> {
  String searchQuery = '';
  String? selectedCategory; // 필터 카테고리

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      context.read<MarkerListViewModel>().fetchMarkers();
    });
  }

  String formatDate(String? createdAt) {
    if (createdAt == null) return '';
    final date = DateTime.tryParse(createdAt);
    return date != null ? DateFormat('yyyy년 M월 d일').format(date) : '';
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
      body: Column(
        children: [
          // 🔍 검색창
          Padding(
            padding: const EdgeInsets.all(AppDesign.spacing16),
            child: TextField(
              decoration: InputDecoration(
                hintText: '장소 검색',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() => searchQuery = value);
              },
            ),
          ),

          // 🏷 카테고리 필터
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppDesign.spacing16),
            child: Row(
              children: [
                categoryChip('전체'),
                categoryChip('카페'),
                categoryChip('호텔'),
                categoryChip('사진'),
                categoryChip('음식점'),
                categoryChip('전시회'),
              ],
            ),
          ),

          const SizedBox(height: AppDesign.spacing8),

          // 📋 리스트
          Expanded(
            child: Consumer<MarkerListViewModel>(
              builder: (context, vm, _) {
                if (vm.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                // 검색 + 필터 적용
                final filteredMarkers = vm.markers.where((marker) {
                  final titleMatch = marker['title']
                      .toString()
                      .toLowerCase()
                      .contains(searchQuery.toLowerCase());
                  final categoryMatch = (selectedCategory == null ||
                      selectedCategory == '전체' ||
                      marker['keyword'] == selectedCategory);
                  return titleMatch && categoryMatch;
                }).toList();

                if (filteredMarkers.isEmpty) {
                  return const Center(child: Text('조건에 맞는 장소가 없습니다.'));
                }

                return RefreshIndicator(
                  onRefresh: () => vm.fetchMarkers(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDesign.spacing16),
                    itemCount: filteredMarkers.length,
                    separatorBuilder: (_, __) =>
                    const SizedBox(height: AppDesign.spacing12),
                    itemBuilder: (context, index) {
                      final markerMap = filteredMarkers[index];
                      final marker = MarkerModel.fromMap(markerMap);

                      return Dismissible(
                        key: Key(marker.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          return await showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text("삭제 확인"),
                              content: Text("'${marker.title}'을(를) 삭제하시겠습니까?"),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(false),
                                  child: const Text("취소"),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(true),
                                  child: const Text("삭제"),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (direction) async {
                          await vm.deleteMarker(context, marker.id);
                        },
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MarkerDetailView(
                                  marker: marker.toGoogleMarker(),
                                  keyword: marker.keyword,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppDesign.spacing16),
                            decoration: BoxDecoration(
                              color: AppDesign.cardBg,
                              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                              boxShadow: AppDesign.softShadow,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(marker.title, style: AppDesign.headingSmall),
                                const SizedBox(height: 4),
                                Text(marker.address, style: AppDesign.bodyMedium),
                                const SizedBox(height: 4),
                                Text(marker.keyword, style: AppDesign.caption),
                                const SizedBox(height: 2),
                                Text(formatDate(markerMap['created_at']), style: AppDesign.caption),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget categoryChip(String label) {
    final isSelected = selectedCategory == label ||
        (selectedCategory == null && label == '전체');
    return Padding(
      padding: const EdgeInsets.only(right: AppDesign.spacing8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedCategory = label;
          });
        },
      ),
    );
  }
}
