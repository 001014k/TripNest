import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/bookmark_viewmodel.dart';
import '../views/markerdetail_view.dart';

class BookmarkView extends StatefulWidget {
  const BookmarkView({Key? key}) : super(key: key);

  @override
  _BookmarkViewState createState() => _BookmarkViewState();
}

class _BookmarkViewState extends State<BookmarkView> {

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<BookmarkViewmodel>();

    return Scaffold(
      appBar: AppBar(
        title: Text('북마크 목록'),
      ),
      body: FutureBuilder<List<Marker>>(
        future: viewModel.loadBookmarks(), // 직접 Firestore에서 북마크 불러오기
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('오류가 발생했습니다: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('북마크가 없습니다.'));
          }

          final markers = snapshot.data!;

          return ListView.builder(
            itemCount: markers.length,
            itemBuilder: (context, index) {
              final marker = markers[index];
              final details =
                  marker.infoWindow.snippet?.split('\n') ?? ['', ''];
              final keyword = details[0];

              return ListTile(
                title: Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.red),
                    SizedBox(width: 8),
                    Text(
                      marker.infoWindow.title ?? '이름 없음',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.label, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          '$keyword', // 키워드
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Divider(),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.info_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MarkerDetailView(
                          marker: marker,
                          keyword: keyword,
                          onSave: (Marker marker, String keyword) {},
                          onDelete: (Marker marker) {},
                          onBookmark: (Marker marker) {},
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
