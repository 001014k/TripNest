import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageviewViewmodel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  Future<bool> deleteImage(String imageUrl) async {
    final user = supabase.auth.currentUser;
    if (user == null) return false;
    try {
      // 1. Supabase DB에서 이미지 URL이 일치하는 레코드 삭제
      await supabase
          .from('marker_images')
          .delete()
          .eq('user_id', user.id)
          .eq('url', imageUrl);

      // 2. Supabase Storage에서 이미지 파일 삭제
      final storagePath = _extractStoragePathFromUrl(imageUrl);
      if (storagePath == null) {
        throw StateError('이미지 경로를 찾을 수 없습니다.');
      }

      await supabase.storage.from('your-bucket-name').remove([storagePath]);

      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      rethrow;
    }
  }

  String? _extractStoragePathFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return null;

    final segments = uri.pathSegments;
    if (segments.length < 6) return null;

    return segments.sublist(5).join('/');
  }
}
