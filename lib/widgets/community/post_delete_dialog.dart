import 'package:flutter/material.dart';

/// Returns a confirmation only; deletion remains owned by the detail screen.
class PostDeleteDialog extends StatelessWidget {
  const PostDeleteDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(17),
                    ),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 30, color: Color(0xFFCA2615)),
                  ),
                  const SizedBox(height: 16),
                  const Text('게시글을 삭제할까요?',
                      style: TextStyle(
                          fontSize: 23,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -.7)),
                  const SizedBox(height: 14),
                  const Text('게시글과 댓글, 좋아요가 함께 삭제됩니다.\n삭제 후에는 되돌릴 수 없습니다.',
                      style: TextStyle(
                          fontSize: 15,
                          height: 1.55,
                          color: Color(0xFF74747E))),
                  const SizedBox(height: 28),
                  Row(children: [
                    Expanded(
                        child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        backgroundColor: const Color(0xFFF3F3F5),
                        foregroundColor: const Color(0xFF25252A),
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('취소',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    )),
                    const SizedBox(width: 8),
                    Expanded(
                        child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC92513),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15)),
                      ),
                      child: const Text('게시글 삭제',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                    )),
                  ]),
                ],
              ),
            ),
          ),
        ),
      );
}
