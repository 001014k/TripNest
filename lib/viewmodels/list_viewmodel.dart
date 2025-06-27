import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/list_model.dart';
import 'dart:async';

class ListViewModel extends ChangeNotifier {
  List<ListModel> lists = [];
  bool isLoading = true;
  String? errorMessage;

  StreamSubscription? _listsSubscription;
  Map<String, StreamSubscription> _bookmarkSubscriptions = {};

  ListViewModel() {
    _subscribeToLists();
  }

  @override
  void dispose() {
    _listsSubscription?.cancel();
    _bookmarkSubscriptions.forEach((_, sub) => sub.cancel());
    super.dispose();
  }

  void _subscribeToLists() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    isLoading = true;
    notifyListeners();

    _listsSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('lists')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      lists = snapshot.docs.map((doc) {
        return ListModel(
          id: doc.id,
          name: doc['name'],
          createdAt: (doc['createdAt'] as Timestamp).toDate(),
          markerCount: 0,
        );
      }).toList();

      _bookmarkSubscriptions.forEach((key, sub) => sub.cancel());
      _bookmarkSubscriptions.clear();

      for (var list in lists) {
        final sub = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('lists')
            .doc(list.id)
            .collection('bookmarks')
            .snapshots()
            .listen((bookmarkSnapshot) {
          final count = bookmarkSnapshot.docs.length;
          final index = lists.indexWhere((l) => l.id == list.id);
          if (index != -1) {
            lists[index] = lists[index].copyWith(markerCount: count);
            notifyListeners();
          }
        });
        _bookmarkSubscriptions[list.id] = sub;
      }

      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      errorMessage = '데이터 로드 중 오류 발생';
      isLoading = false;
      notifyListeners();
    });
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
