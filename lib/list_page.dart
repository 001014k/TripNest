import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'markerinfo_page.dart';

class ListPage extends StatefulWidget {
  @override
  _ListPageState createState() => _ListPageState();
}

class _ListPageState extends State<ListPage> {
  final TextEditingController _listNameController = TextEditingController();

  Future<void> _createList() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .add({
        'name': _listNameController.text,
        'createdAt': Timestamp.now(),
      });

      _listNameController.clear();
    }
  }

  Future<void> _deleteList(String listId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final batch = FirebaseFirestore.instance.batch();
      final listRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId);

      final bookmarksRef = listRef.collection('bookmarks');
      final bookmarksSnapshot = await bookmarksRef.get();
      for (var doc in bookmarksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      batch.delete(listRef);
      await batch.commit();
    }
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('새 리스트 생성'),
          content: TextField(
            controller: _listNameController,
            decoration: InputDecoration(labelText: '리스트 이름'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                _createList();
                Navigator.of(context).pop();
              },
              child: Text('생성'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('취소'),
            ),
          ],
        );
      },
    );
  }

  void _showListOptions(String listId) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: Icon(Icons.info),
              title: Text('리스트 내 마커 정보 보기'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => MarkerInfoPage(listId: listId),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.delete),
              title: Text('리스트 삭제'),
              onTap: () async {
                Navigator.pop(context);
                // Confirm deletion
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: Text('리스트 삭제'),
                      content: Text('리스트를 삭제할건가요?'),
                      actions: [
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('삭제'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('취소'),
                        ),
                      ],
                    );
                  },
                );
                if (confirm == true) {
                  await _deleteList(listId);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<int> _getMarkerCount(String listId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final bookmarksRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId)
          .collection('bookmarks');

      final bookmarksSnapshot = await bookmarksRef.get();
      return bookmarksSnapshot.docs.length;
    }
    return 0;
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('경로 리스트'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth.instance.currentUser!.uid)
            .collection('lists')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final lists = snapshot.data!.docs;

          return ListView.builder(
            itemCount: lists.length,
            itemBuilder: (context, index) {
              final list = lists[index];
              return FutureBuilder<int>(
                future: _getMarkerCount(list.id),
                builder: (context, markerSnapshot) {
                  final markerCount = markerSnapshot.data ?? 0;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.list_alt),
                          title: Text(
                            list['name'],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('마커 갯수: $markerCount'), // 마커 수 표시
                          onTap: () {
                            _showListOptions(list.id);
                          },
                        ),
                        Divider(),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateListDialog,
        child: Icon(Icons.add),
      ),
    );
  }
}
