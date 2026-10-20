import 'package:flutter/foundation.dart';

import '../services/address_photo_preview_service.dart';

class AddressPhotoPreviewViewModel extends ChangeNotifier {
  AddressPhotoPreviewViewModel(this.address, this.title) {
    _loadPhotoUrl();
  }

  final String address;
  final String? title;
  final AddressPhotoPreviewService _service =
      const AddressPhotoPreviewService();

  String? _photoUrl;
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;

  String? get photoUrl => _photoUrl;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _loadPhotoUrl() async {
    _isLoading = true;
    _error = null;
    _notify();
    try {
      _photoUrl = await _service.load(address, title);
      if (_photoUrl == null) _error = '장소 사진이 없습니다.';
    } catch (error) {
      _error = error.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> refresh() async {
    await _service.clear(address, title);
    await _loadPhotoUrl();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
