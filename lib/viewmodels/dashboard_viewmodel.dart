import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';


class DashboardViewModel extends ChangeNotifier {
  int totalUsers = 0;
  int totalMarkers = 0;
  Map<String, int> userMarkersCount = {};

  Future<void> fetchDashboardData() async {
    QuerySnapshot usersSnapshot =
    await FirebaseFirestore.instance.collection('users').get();
    totalUsers = usersSnapshot.docs.length;

    for (var userDoc in usersSnapshot.docs) {
      String email = userDoc['email'];
      QuerySnapshot markersSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(userDoc.id)
          .collection('user_markers')
          .get();

      int userMarkerCount = markersSnapshot.docs.length;
      totalMarkers += userMarkerCount;
      userMarkersCount[email] = userMarkerCount;
    }
  }
}