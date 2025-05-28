import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';
import 'connectivity_service.dart';

class MarkerService {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ConnectivityService _connectivityService = ConnectivityService();

  Future<void> saveMarkerOfflineOrOnline(
      Map<String, dynamic> markerData) async {
    final isConnected = await _connectivityService.isConnected();

    if (!isConnected) {
      // 오프라인일 때 SQLite에 저장
      await _dbHelper.insertMarker(markerData);
    } else {
      // 온라인일 때 Firebase에 저장
      final userId = "your_user_id"; // 실제 사용자 ID로 변경
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('markers')
          .doc(markerData['id'])
          .set({
        'title': markerData['title'],
        'description': markerData['description'],
        'latitude': markerData['latitude'],
        'longitude': markerData['longitude'],
      });

      // 동기화 상태 업데이트
      await _dbHelper.insertMarker({...markerData, 'synced': 1});
    }
  }

  Future<void> syncOfflineMarkers() async {
    final unsyncedMarkers = await _dbHelper.getUnsyncedMarkers();

    for (final marker in unsyncedMarkers) {
      final userId = "your_user_id"; // 실제 사용자 ID로 변경

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('markers')
          .doc(marker['id'])
          .set({
        'title': marker['title'],
        'description': marker['description'],
        'latitude': marker['latitude'],
        'longitude': marker['longitude'],
      });

      // 동기화 상태 업데이트
      await _dbHelper.updateMarkerSyncStatus(marker['id']);
    }
  }
}
