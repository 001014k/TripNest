import 'package:flutter/services.dart';

class AppGroupService {
  static const MethodChannel _channel = MethodChannel('com.fluttertrip.appgroup');

  /// AppGroup에서 공유 주소 읽기
  static Future<String?> readSharedAddress() async {
    try {
      final String? sharedAddress = await _channel.invokeMethod<String>('getSharedAddress');
      return sharedAddress;
    } catch (e) {
      print('❌ 공유 주소 읽기 실패: $e');
      return null;
    }
  }

  /// 읽은 주소 제거 (중복 방지)
  static Future<void> clearSharedAddress() async {
    try {
      await _channel.invokeMethod('clearSharedAddress');
    } catch (e) {
      print('❌ 공유 주소 삭제 실패: $e');
    }
  }
}
