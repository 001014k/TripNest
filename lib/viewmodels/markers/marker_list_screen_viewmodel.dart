import '../../services/infrastructure/paged_rows.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MarkerListViewModel extends ChangeNotifier {
  bool _accountDisposed = false;
  @override
  void notifyListeners() {
    if (!_accountDisposed) super.notifyListeners();
  }

  final SupabaseClient supabase;
  bool isLoading = false;
  String? errorMessage;
  int _revision = 0;
  final Set<String> _deleted = {}, _deleting = {};
  List<Map<String, dynamic>> markers = [];

  MarkerListViewModel(this.supabase);

  Future<void> fetchMarkers() async {
    final revision = ++_revision;
    _deleted.clear();
    isLoading = true;
    notifyListeners();

    try {
      final user = supabase.auth.currentUser;
      if (user == null) {
        markers = [];
        return;
      }

      final data = await loadRowsById(
          () => supabase
              .from('user_markers')
              .select(
                  'id, title, address, keyword, created_at, lat, lng, marker_image_path')
              .eq('user_id', user.id),
          isCancelled: () => _accountDisposed || revision != _revision);
      if (_accountDisposed ||
          revision != _revision ||
          supabase.auth.currentUser?.id != user.id) {
        return;
      }
      errorMessage = null;
      markers = data
          .where((m) =>
              !_deleted.contains(m['id']) && !_deleting.contains(m['id']))
          .toList()
        ..sort((a, b) =>
            b['created_at'].toString().compareTo(a['created_at'].toString()));
    } catch (e) {
      if (!_accountDisposed && revision == _revision) {
        errorMessage = '저장한 장소를 불러오지 못했어요.';
      }
    } finally {
      if (revision == _revision) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<bool> deleteMarker(String markerId) async {
    if (!_deleting.add(markerId)) return false;
    ++_revision;
    isLoading = false;
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return false;

      final deleted = await supabase
          .from('user_markers')
          .delete()
          .eq('id', markerId)
          .eq('user_id', user.id)
          .select('id');
      if (deleted.isEmpty) throw StateError('삭제되지 않았습니다.');
      ++_revision;
      isLoading = false;
      _deleted.add(markerId);

      // 성공적으로 삭제되면 리스트에서 제거
      markers.removeWhere((m) => m['id'] == markerId);
      notifyListeners();

      return true;
    } catch (e) {
      debugPrint('deleteMarker error: $e');
      _deleting.remove(markerId);
      await fetchMarkers();
      return false;
    } finally {
      _deleting.remove(markerId);
    }
  }

  @override
  void dispose() {
    _accountDisposed = true;
    super.dispose();
  }
}
