import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';

class AddMarkersToListPage extends StatelessWidget {
  final String listId;

  const AddMarkersToListPage({required this.listId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddMarkersToListViewModel()..loadMarkers()..loadMarkersInList(listId),
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Markers to List', style: TextStyle(fontWeight: FontWeight.w600)),
          elevation: 1,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
        ),
        body: Consumer<AddMarkersToListViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (viewModel.error != null) {
              return Center(
                child: Text(
                  viewModel.error!,
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                ),
              );
            } else {
              final markers = viewModel.markers.toList();
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: markers.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  final isSelected = viewModel.isMarkerInList(marker, listId);
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => viewModel.addMarkerToList(marker, listId, context),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.location_on_outlined,
                              color: isSelected ? Colors.green : Colors.blueGrey,
                              size: 28,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                marker.infoWindow.title ?? 'No Title',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}
