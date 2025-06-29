import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageviewViewmodel extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  Future<void> deleteImage(String imageUrl, BuildContext context) async {
    final user = supabase.auth.currentUser;
    if (user != null) {
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('이미지 경로를 찾을 수 없습니다.')),
          );
          return;
        }

        await supabase.storage.from('your-bucket-name').remove([storagePath]);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진이 삭제되었습니다.')),
        );
        Navigator.pop(context, true);
      } catch (e) {
        print('Error deleting image: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('사진 삭제 중 오류가 발생했습니다.')),
        );
      }
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
