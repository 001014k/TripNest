import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/marker_info_viewmodel.dart';

class MarkerInfoPage extends StatelessWidget {
  final String listId;

  MarkerInfoPage({required this.listId});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MarkerInfoViewModel(listId: listId),
      child: Scaffold(
        appBar: AppBar(title: Text('Marker Info')),
        body: Consumer<MarkerInfoViewModel>(
          builder: (context, viewModel, child) {
            if (viewModel.isLoading) {
              return Center(child: CircularProgressIndicator());
            }

            if (viewModel.error != null) {
              return Center(child: Text(viewModel.error!, style: TextStyle(color: Colors.red)));
            }

            if (viewModel.markers.isEmpty) {
              return Center(child: Text('No markers found.'));
            }

            return ListView.builder(
              itemCount: viewModel.markers.length,
              itemBuilder: (context, index) {
                final marker = viewModel.markers[index];

                return FutureBuilder<String>(
                  future: viewModel.getAddress(marker.lat, marker.lng),
                  builder: (context, snapshot) {
                    String address = snapshot.data ?? 'Loading address...';

                    return Column(
                      children: [
                        ListTile(
                          contentPadding: EdgeInsets.all(16),
                          leading: Icon(Icons.location_on, color: Colors.blue),
                          title: Text(
                            marker.title,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          subtitle: Text(address),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(context, viewModel, marker.id),
                          ),
                        ),
                        Divider(color: Colors.grey, thickness: 1),
                      ],
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

  void _confirmDelete(BuildContext context, MarkerInfoViewModel viewModel, String markerId) async {
    final result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('삭제 확인'),
          content: Text('이 마커를 삭제하시겠습니까?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text('삭제', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text('취소'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      viewModel.deleteMarker(markerId);
    }
  }
}
