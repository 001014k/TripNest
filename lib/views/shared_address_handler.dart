import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/app_group_handler_service.dart';
import '../viewmodels/shared_link_viewmodel.dart';

Future<void> handleIncomingSharedAddress(
  BuildContext context, {
  bool navigateToSharedLink = true,
}) async {
  try {
    final address = await SharedAppGroupHandler.takeSharedAddress();
    if (address == null || !context.mounted) return;

    context.read<SharedLinkViewModel>().queueIncomingLink(
          address.url,
          sharedText: address.text,
        );
    final currentRoute = ModalRoute.of(context)?.settings.name;
    if (navigateToSharedLink &&
        currentRoute != '/shared_link' &&
        currentRoute != '/splash') {
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/shared_link',
        (route) => route.settings.name == '/home',
      );
    }
  } catch (error) {
    debugPrint('공유 주소 처리 오류: $error');
  }
}
