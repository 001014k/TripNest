import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodels/shared_link_viewmodel.dart';
import 'package:provider/provider.dart';

class SharedAppGroupHandler {
  static const MethodChannel _channel = MethodChannel('com.fluttertrip.appgroup');

  static Future<void> checkAndHandleSharedAddress(BuildContext context) async {
    print('🔍 checkAndHandleSharedAddress 호출됨');

    try {
      final String? sharedText = await _channel.invokeMethod<String>('getSharedAddress');
      print('🔍 getSharedAddress 반환값: $sharedText');

      if (sharedText != null && sharedText.isNotEmpty) {
        print("📦 공유된 주소 감지됨: $sharedText");

        // Provider로 등록된 ViewModel을 context에서 읽어서 사용 (권장)
        final viewModel = context.read<SharedLinkViewModel>();
        await viewModel.saveLink(sharedText);

        if (context.mounted) {
          final message = viewModel.errorMessage == null
              ? '✅ 공유 링크가 저장되었습니다!'
              : '❌ 저장 실패: ${viewModel.errorMessage}';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }

        await _channel.invokeMethod('clearSharedAddress');
        print('🔍 clearSharedAddress 호출 완료');
      } else {
        print('ℹ️ 공유된 주소가 없습니다.');
      }
    } catch (e) {
      print("❌ AppGroup 주소 처리 오류: $e");
    }
  }
}
