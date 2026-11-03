import 'package:flutter/foundation.dart';
import '../../services/onboarding/onboarding_service.dart';

class OnboardingViewModel extends ChangeNotifier {
  OnboardingViewModel({OnboardingService? service})
      : _service = service ?? OnboardingService();
  final OnboardingService _service;
  int page = 0;
  bool saving = false;
  bool _disposed = false;
  String? error;
  void select(int value) {
    page = value;
    notifyListeners();
  }

  Future<bool> finish() async {
    if (saving) return false;
    saving = true;
    error = null;
    notifyListeners();
    try {
      await _service.markSeen(OnboardingService.introKey);
      return true;
    } catch (_) {
      error = '안내 기록을 저장하지 못했어요. 다시 시도해주세요.';
      return false;
    } finally {
      saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
