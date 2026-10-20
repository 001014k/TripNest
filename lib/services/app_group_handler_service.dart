import 'package:flutter/services.dart';

typedef SharedAddress = ({String url, String text});

class SharedAppGroupHandler {
  static const MethodChannel _channel =
      MethodChannel('com.fluttertrip.appgroup');

  static Future<SharedAddress?> takeSharedAddress() async {
    final sharedText = await _channel.invokeMethod<String>('getSharedAddress');
    if (sharedText == null || sharedText.isEmpty) return null;

    final match = RegExp(r'https?://[^\s]+').firstMatch(sharedText);
    final url = match?.group(0)?.replaceFirst(RegExp(r'[)\],.!]+$'), '');
    await _channel.invokeMethod('clearSharedAddress');
    if (url == null || url.isEmpty) return null;
    return (url: url, text: sharedText);
  }
}
