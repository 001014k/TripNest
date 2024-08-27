import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'addmarkerstolist_page.dart';
import 'main.dart';
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
      // Get the batch instance to perform multiple operations
      final batch = FirebaseFirestore.instance.batch();

      // Reference to the list document
      final listRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .doc(listId);

      // Reference to the bookmarks subcollection
      final bookmarksRef = listRef.collection('bookmarks');

      // Delete all documents in the bookmarks subcollection
      final bookmarksSnapshot = await bookmarksRef.get();
      for (var doc in bookmarksSnapshot.docs) {
        batch.delete(doc.reference);
      }

      // Delete the list document itself
      batch.delete(listRef);

      // Commit the batch
      await batch.commit();
    }
  }

  void _showCreateListDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Create New List'),
          content: TextField(
            controller: _listNameController,
            decoration: InputDecoration(labelText: 'List Name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _createList();
                Navigator.of(context).pop();
              },
              child: Text('Create'),
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
                      title: Text('Delete List'),
                      content: Text('Are you sure you want to delete this list and all its markers?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: Text('Cancel'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: Text('Delete'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Lists'),
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
              return ListTile(
                title: Text(list['name']),
                onTap: () {
                  _showListOptions(list.id);
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
