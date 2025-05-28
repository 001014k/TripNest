import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';

class ImageviewViewmodel extends ChangeNotifier {


  Future<void> deleteImage(String imageUrl, BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        // Firestore에서 이미지 URL 삭제
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('marker_images')
            .where('url', isEqualTo: imageUrl)
            .get();

        for (var doc in snapshot.docs) {
          await doc.reference.delete();
        }

        // Firebase Storage에서 이미지 삭제
        final storageRef = FirebaseStorage.instance.refFromURL(imageUrl);
        await storageRef.delete();

        // 로컬 리스트에서 이미지 삭제
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진이 삭제되었습니다.')),
        );
        Navigator.pop(context, true); // 이미지 뷰어 페이지 종료
      } catch (e) {
        print('Error deleting image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 삭제 중 오류가 발생했습니다.')),
        );
      }
    }
  }
}