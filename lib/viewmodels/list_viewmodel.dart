import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/list_model.dart';

class ListViewModel extends ChangeNotifier {
  List<ListModel> lists = [];
  bool isLoading = true;
  String? errorMessage;

  ListViewModel() {
    fetchLists();
  }

  Future<void> fetchLists() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .orderBy('createdAt', descending: true)
          .get();

      lists = await Future.wait(snapshot.docs.map((doc) async {
        final markerCount = await _getMarkerCount(user.uid, doc.id);
        return ListModel(
          id: doc.id,
          name: doc['name'],
          createdAt: (doc['createdAt'] as Timestamp).toDate(),
          markerCount: markerCount,
        );
      }).toList());

      errorMessage = null;
    } catch (e) {
      errorMessage = '데이터를 불러오는 중 오류 발생';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<int> _getMarkerCount(String userId, String listId) async {
    final bookmarksSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('lists')
        .doc(listId)
        .collection('bookmarks')
        .get();

    return bookmarksSnapshot.docs.length;
  }

  Future<void> createList(String name) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final docRef = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('lists')
          .add({'name': name, 'createdAt': Timestamp.now()});

      lists.insert(0, ListModel(id: docRef.id, name: name, createdAt: DateTime.now(), markerCount: 0));
      notifyListeners();
    } catch (e) {
      errorMessage = '리스트 생성 중 오류 발생';
      notifyListeners();
    }
  }

  Future<void> deleteList(String listId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
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

      lists.removeWhere((list) => list.id == listId);
      notifyListeners();
    } catch (e) {
      errorMessage = '리스트 삭제 중 오류 발생';
      notifyListeners();
    }
  }
}
