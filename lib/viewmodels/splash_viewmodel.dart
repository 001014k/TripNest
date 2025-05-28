import 'package:flutter/material.dart';
import 'dart:async';

class SplashViewModel extends ChangeNotifier {
  bool _isLoading = true;

  bool get isLoading => _isLoading;

  /// 3초 후 `LoginPage`로 이동
  Future<void> startSplash(Function navigateToNext) async {
    await Future.delayed(Duration(seconds: 3));
    _isLoading = false;
    notifyListeners();
    navigateToNext();
  }
}
