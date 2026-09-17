import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../viewmodels/shared_link_viewmodel.dart';
import 'package:provider/provider.dart';

class SharedAppGroupHandler {
  static const MethodChannel _channel =
      MethodChannel('com.fluttertrip.appgroup');

  static Future<void> checkAndHandleSharedAddress(
    BuildContext context, {
    bool navigateToSharedLink = true,
  }) async {
    debugPrint('공유 주소 확인을 시작합니다.');

    try {
      final String? sharedText =
          await _channel.invokeMethod<String>('getSharedAddress');
      debugPrint('공유 주소 수신 여부: ${sharedText != null}');

      if (sharedText != null && sharedText.isNotEmpty) {
        debugPrint('공유된 주소를 확인했습니다.');
        if (!context.mounted) return;

        // 공유 데이터에서 실제 URL만 추출합니다.
        // Instagram처럼 설명 문구 + URL이 함께 전달되는 경우를 처리합니다.
        final urlRegex = RegExp(r'https?://[^\s]+');
        final match = urlRegex.firstMatch(sharedText);

        if (match != null) {
          final rawUrl = match.group(0)!;

          // URL 끝에 붙을 수 있는 불필요한 문장부호 제거
          final url = rawUrl.replaceFirst(
            RegExp(r'[)\],.!]+$'),
            '',
          );

          debugPrint('🔗 공유 데이터에서 URL 추출: $url');

          // 링크를 바로 저장하지 않고,
          // 장소 추출과 사용자 확인 화면으로 전달합니다.
          final viewModel = context.read<SharedLinkViewModel>();
          viewModel.queueIncomingLink(
            url,
            sharedText: sharedText,
          );
        } else {
          debugPrint('⚠️ 공유 데이터에서 URL을 찾지 못했습니다.');
          debugPrint('📄 공유 원문: $sharedText');
        }

        await _channel.invokeMethod('clearSharedAddress');
        debugPrint('공유 주소를 초기화했습니다.');
        if (!context.mounted) return;

        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (navigateToSharedLink &&
            context.mounted &&
            currentRoute != '/shared_link' &&
            currentRoute != '/splash') {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/shared_link',
            (route) => route.settings.name == '/home',
          );
        }
      } else {
        debugPrint('공유된 주소가 없습니다.');
      }
    } catch (e) {
      debugPrint('AppGroup 공유 주소 처리 오류: $e');
    }
  }
}
