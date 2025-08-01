import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/marker_info_viewmodel.dart';
import '../views/add_markers_to_list_view.dart';

class MarkerInfoPage extends StatefulWidget {
  final String listId;

  const MarkerInfoPage({Key? key, required this.listId}) : super(key: key);

  @override
  _MarkerInfoPageState createState() => _MarkerInfoPageState();
}

class _MarkerInfoPageState extends State<MarkerInfoPage> {
  int _selectedIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  late MarkerInfoViewModel viewModel;

  @override
  void initState() {
    super.initState();
    viewModel = MarkerInfoViewModel(listId: widget.listId);
  }

  @override
  void dispose() {
    _searchController.dispose();
    viewModel.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    if (index == 0) {
      navigateToAddMarkersToListPage();
    }
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
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Marker Info', style: TextStyle(fontWeight: FontWeight.w600)),
          elevation: 4,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: navigateToAddMarkersToListPage,
          child: Icon(Icons.add_location),
        ),
        body: Consumer<MarkerInfoViewModel>(
          builder: (context, vm, child) {
            if (vm.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (vm.error != null) {
              return Center(
                child: Text(
                  vm.error!,
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                ),
              );
            }

            if (vm.markers.isEmpty) {
              return const Center(
                child: Text(
                  '마커가 없습니다. 추가해주세요.',
                  style: TextStyle(fontSize: 16, color: Colors.black54),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: vm.markers.length,
              itemBuilder: (context, index) {
                final marker = vm.markers[index];

                return FutureBuilder<Map<String, String>>(
                  future: vm.fetchMarkerDetail(marker.id),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final details = snapshot.data!;
                    final title = details['title'] ?? '제목 없음';
                    final address = details['address'] ?? '주소 없음';
                    final keyword = details['keyword'] ?? '키워드 없음';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 6,
                      color: Colors.white.withOpacity(0.95), // Glass 느낌
                      shadowColor: Colors.grey.withOpacity(0.4),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const CircleAvatar(
                                  radius: 20,
                                  backgroundColor: Colors.blueAccent,
                                  child: Icon(Icons.place, color: Colors.white),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_forever_rounded, color: Colors.redAccent, size: 28),
                                  onPressed: () => _confirmDelete(context, vm, marker.id),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Icon(Icons.location_city, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    address,
                                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                const Icon(Icons.label_outline, size: 18, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(
                                  keyword,
                                  style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
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
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueGrey,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontWeight: FontWeight.bold),
              ),
              child: const Text('삭제'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.grey[700],
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
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
