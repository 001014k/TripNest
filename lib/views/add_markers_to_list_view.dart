import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/add_markers_to_list_viewmodel.dart';

class AddMarkersToListPage extends StatelessWidget {
  final String listId;

  const AddMarkersToListPage({required this.listId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AddMarkersToListViewModel()..loadMarkers(),
      child: Scaffold(
        appBar: AppBar(title: Text('Add Markers to List')),
        body: Consumer<AddMarkersToListViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            } else if (viewModel.error != null) {
              return Center(child: Text(viewModel.error!));
            } else {
              final markers = viewModel.markers.toList();
              return ListView.builder(
                itemCount: markers.length,
                itemBuilder: (context, index) {
                  final marker = markers[index];
                  return ListTile(
                    title: Text(marker.infoWindow.title ?? 'No Title'),
                    onTap: () => viewModel.addMarkerToList(marker, listId, context),
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
