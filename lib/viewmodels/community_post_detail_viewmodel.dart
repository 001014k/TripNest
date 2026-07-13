import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/community_post_model.dart';

class CommunityPostDetailViewModel extends ChangeNotifier {
  CommunityPostDetailViewModel({required this.postId, SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final String postId;
  final SupabaseClient _client;
  final List<CommunityComment> _comments = [];

  List<CommunityComment> get comments => List.unmodifiable(_comments);
  bool isLoading = false;
  bool isSubmittingComment = false;
  bool isLiked = false;
  int likeCount = 0;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _client
            .from('travel_post_likes')
            .select('user_id')
            .eq('post_id', postId),
        _client
            .from('travel_post_comments')
            .select('id, content, author_id, created_at, profiles(nickname)')
            .eq('post_id', postId)
            .order('created_at'),
      ]);
      final likes = results[0] as List;
      final currentUserId = _client.auth.currentUser?.id;
      likeCount = likes.length;
      isLiked = currentUserId != null &&
          likes.any((like) =>
              (like as Map<String, dynamic>)['user_id'] == currentUserId);
      _comments
        ..clear()
        ..addAll(
          (results[1] as List).map(
            (data) => CommunityComment.fromMap(data as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      errorMessage = '좋아요와 댓글을 불러오지 못했습니다.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      errorMessage = '로그인 후 좋아요를 누를 수 있습니다.';
      notifyListeners();
      return;
    }

    final wasLiked = isLiked;
    isLiked = !wasLiked;
    likeCount += wasLiked ? -1 : 1;
    notifyListeners();

    try {
      if (wasLiked) {
        await _client
            .from('travel_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        await _client.from('travel_post_likes').insert({
          'post_id': postId,
          'user_id': user.id,
        });
      }
    } catch (_) {
      isLiked = wasLiked;
      likeCount += wasLiked ? 1 : -1;
      errorMessage = '좋아요를 반영하지 못했습니다.';
      notifyListeners();
    }
  }

  Future<bool> addComment(String content) async {
    final user = _client.auth.currentUser;
    final trimmed = content.trim();
    if (user == null || trimmed.isEmpty) return false;

    isSubmittingComment = true;
    notifyListeners();
    try {
      await _client.from('travel_post_comments').insert({
        'post_id': postId,
        'author_id': user.id,
        'content': trimmed,
      });
      await load();
      return true;
    } catch (_) {
      errorMessage = '댓글을 등록하지 못했습니다.';
      return false;
    } finally {
      isSubmittingComment = false;
      notifyListeners();
    }
  }
}
