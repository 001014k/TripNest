import 'package:flutter/material.dart';
import '../common/app_overlays.dart';

/// 확인 결과만 반환하며 실제 삭제는 상세 화면에서 처리합니다.
class PostDeleteDialog extends StatelessWidget {
  const PostDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) => const AppConfirmDialog(
        title: '게시글을 삭제할까요?',
        message: '게시글과 댓글, 좋아요가 함께 삭제됩니다.\n삭제 후에는 되돌릴 수 없습니다.',
        confirmLabel: '게시글 삭제',
        destructive: true,
        icon: Icons.delete_outline_rounded,
      );
}
