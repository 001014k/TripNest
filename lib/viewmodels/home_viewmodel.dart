import 'package:flutter/material.dart';
import '../models/marker_model.dart';
import '../models/shared_link_model.dart';  // SharedLinkModel 임포트
import '../services/marker_service.dart';
import '../services/shared_link_service.dart';  // 공유 링크를 가져올 서비스 (예시)

class HomeDashboardViewModel extends ChangeNotifier {
  final List<MarkerModel> _recentMarkers = [];
  final List<SharedLinkModel> _sharedLinks = [];

  List<MarkerModel> get recentMarkers => _recentMarkers;
  List<SharedLinkModel> get sharedLinks => _sharedLinks;

  Future<void> loadRecentMarkers() async {
    final rawMarkers = await MarkerService().getRecentMarkers(limit: 3);
    _recentMarkers.clear();
    _recentMarkers.addAll(rawMarkers.map((e) => MarkerModel.fromMap(e)));
    notifyListeners();
  }

  // 공유 링크 불러오는 함수 추가
  Future<void> loadSharedLinks() async {
    final rawLinks = await SharedLinkService().loadSharedLinks(); // ✅ 수정된 부분
    _sharedLinks.clear();
    _sharedLinks.addAll(rawLinks);
    notifyListeners();
  }
}
