import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/community/community_post_model.dart';

class CommunityPostDetailViewModel extends ChangeNotifier {
  CommunityPostDetailViewModel({required this.postId, SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final String postId;
  final SupabaseClient _client;
  final List<CommunityComment> _comments = [];

  List<CommunityComment> get comments => List.unmodifiable(_comments);
  bool isLoading = false;
  bool isLiking = false;
  bool isLoadingMore = false;
  bool hasMoreComments = true;
  bool newestFirst = true;
  int commentCount = 0;
  int _revision = 0;
  Map<String, dynamic>? _cursor;
  Future<void> changeCommentOrder(bool newest) async {
    newestFirst = newest;
    await load();
  }

  bool isSubmittingComment = false;
  bool isLiked = false;
  int likeCount = 0;
  String? errorMessage;

  bool isSavingPlace = false;
  bool isPlaceSaved = false;

  Future<String> savePlace() async {
    if (isSavingPlace) return '';
    if (_client.auth.currentUser == null) return '로그인 후 장소를 저장할 수 있습니다.';
    isSavingPlace = true;
    notifyListeners();
    try {
      final result = await _client
          .rpc('save_community_place', params: {'p_post_id': postId});
      isPlaceSaved = true;
      return result['already_saved'] == true
          ? '이미 내 지도에 저장된 장소입니다.'
          : '내 지도에 장소를 저장했습니다.';
    } catch (_) {
      return '장소를 저장하지 못했습니다. 다시 시도해주세요.';
    } finally {
      isSavingPlace = false;
      notifyListeners();
    }
  }

  bool isDeleting = false;
  bool _disposed = false;

  bool canDelete(String authorId) => _client.auth.currentUser?.id == authorId;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _revision++;
    super.dispose();
  }

  Future<bool> deletePost(String authorId) async {
    if (isDeleting || !canDelete(authorId)) return false;
    isDeleting = true;
    errorMessage = null;
    notifyListeners();
    try {
      final deleted = await _client
          .from('travel_posts')
          .delete()
          .eq('id', postId)
          .eq('author_id', _client.auth.currentUser!.id)
          .select('id');
      if (deleted.isEmpty) throw StateError('Post was not deleted');
      return true;
    } catch (_) {
      errorMessage = '게시글을 삭제하지 못했습니다. 다시 시도해주세요.';
      return false;
    } finally {
      isDeleting = false;
      notifyListeners();
    }
  }

  Future<void> load() => _loadComments(false);
  Future<void> loadMoreComments() => _loadComments(true);
  Future<void> _loadComments(bool append) async {
    if (append && (isLoading || isLoadingMore || !hasMoreComments)) return;
    final revision = ++_revision;
    if (append) {
      isLoadingMore = true;
    } else {
      isLoading = true;
    }
    errorMessage = null;
    notifyListeners();
    try {
      var query = _client
          .from('travel_post_comments')
          .select('id, content, author_id, created_at, profiles(nickname)')
          .eq('post_id', postId);
      if (append && _cursor != null) {
        final op = newestFirst ? 'lt' : 'gt';
        query = query.or(
            'created_at.$op.${_cursor!['created_at']},and(created_at.eq.${_cursor!['created_at']},id.$op.${_cursor!['id']})');
      }
      final rows = await query
          .order('created_at', ascending: !newestFirst)
          .order('id', ascending: !newestFirst)
          .limit(30);
      final stats = append
          ? null
          : await _client
              .rpc('community_post_stats', params: {'p_post_id': postId});
      if (_disposed || revision != _revision) return;
      if (!append) {
        _comments.clear();
        likeCount = (stats['likes'] as num).toInt();
        commentCount = (stats['comments'] as num).toInt();
        if (!isLiking) isLiked = stats['liked'] == true;
      }
      final ids = _comments.map((c) => c.id).toSet();
      _comments.addAll(
          rows.map(CommunityComment.fromMap).where((c) => ids.add(c.id)));
      _cursor = rows.isEmpty ? null : rows.last;
      hasMoreComments = rows.length == 30;
    } catch (_) {
      if (!_disposed && revision == _revision) {
        errorMessage = '댓글을 불러오지 못했습니다. 다시 시도해주세요.';
      }
    } finally {
      if (!_disposed && revision == _revision) {
        isLoading = false;
        isLoadingMore = false;
        notifyListeners();
      }
    }
  }

  Future<void> toggleLike() async {
    if (isLiking || isLoading || _disposed) return;
    final user = _client.auth.currentUser;
    if (user == null) {
      errorMessage = '로그인 후 좋아요를 누를 수 있습니다.';
      notifyListeners();
      return;
    }

    isLiking = true;
    errorMessage = null;
    String? failure;
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
      failure = '좋아요를 반영하지 못했습니다. 다시 시도해주세요.';
    } finally {
      isLiking = false;
      if (!_disposed) {
        await load();
        if (failure != null) errorMessage = failure;
      }
      notifyListeners();
    }
  }

  final Map<String, String> _pendingComments = {};
  Future<bool> addComment(String content) async {
    final user = _client.auth.currentUser;
    if (isSubmittingComment || _disposed) return false;
    final trimmed = content.trim();
    if (user == null || trimmed.isEmpty) return false;

    final operationKey = '${user.id}:$trimmed';
    final commentId =
        _pendingComments.putIfAbsent(operationKey, () => const Uuid().v4());
    isSubmittingComment = true;
    notifyListeners();
    try {
      await _client.from('travel_post_comments').upsert({
        'id': commentId,
        'post_id': postId,
        'author_id': user.id,
        'content': trimmed,
      }, onConflict: 'id', ignoreDuplicates: true);
      _pendingComments.remove(operationKey);
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
