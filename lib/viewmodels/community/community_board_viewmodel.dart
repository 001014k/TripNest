import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/community/community_post_model.dart';

class CommunityBoardViewModel extends ChangeNotifier {
  CommunityBoardViewModel({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;
  final List<CommunityPost> _posts = [];
  final List<CommunityMarker> _myMarkers = [];

  List<CommunityPost> get posts => List.unmodifiable(_posts);
  List<CommunityMarker> get myMarkers => List.unmodifiable(_myMarkers);
  bool _disposed = false;
  final Map<String, int> likeCounts = {};
  final Map<String, int> commentCounts = {};
  final Set<String> likedPosts = {};
  final Set<String> pendingLikes = {};

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  Future<String?> toggleLike(String postId) async {
    final user = _client.auth.currentUser;
    if (user == null) return '로그인 후 좋아요를 누를 수 있습니다.';
    if (!pendingLikes.add(postId)) return null;
    notifyListeners();
    final wasLiked = likedPosts.contains(postId);
    try {
      if (wasLiked) {
        await _client
            .from('travel_post_likes')
            .delete()
            .eq('post_id', postId)
            .eq('user_id', user.id);
      } else {
        await _client
            .from('travel_post_likes')
            .insert({'post_id': postId, 'user_id': user.id});
      }
      await loadPosts();
      return null;
    } catch (_) {
      return '좋아요를 반영하지 못했습니다. 다시 시도해주세요.';
    } finally {
      pendingLikes.remove(postId);
      notifyListeners();
    }
  }

  bool isLoading = false;
  bool isLoadingMarkers = false;
  String? errorMessage;

  String sort = 'recent', topic = '전체';
  double? latitude, longitude;
  String? _feedSnapshot;
  int _feedAfter = 0;
  int _postsRequest = 0;
  Future<void> filterPosts(
      {String? order, String? category, double? lat, double? lng}) {
    sort = order ?? sort;
    topic = category ?? topic;
    if (lat != null) latitude = lat;
    if (lng != null) longitude = lng;
    return loadPosts();
  }

  Map<String, dynamic>? _postCursor;
  bool hasMorePosts = true;
  Future<void> loadMorePosts() => loadPosts(append: true);

  Future<void> loadPosts({bool append = false}) async {
    if (append && (isLoading || !hasMorePosts)) return;
    final request = ++_postsRequest;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      var query = _client.from('travel_posts').select('''
          id, 
          title, 
          content, 
          destination, 
          author_id, 
          created_at, 
          marker_id, 
          place_title, 
          place_address, 
          place_category, 
          place_lat, 
          place_lng, 
          place_image_path,
          profiles!travel_posts_author_id_fkey(nickname),
          travel_post_likes(count),
          travel_post_comments(count)
          ''');
      if (append && _postCursor != null) {
        final date = _postCursor!['created_at'];
        query = query.or(
            'created_at.lt.$date,and(created_at.eq.$date,id.lt.${_postCursor!['id']})');
      }
      final usesSnapshot = sort != 'recent' || topic != '전체';
      Map<String, dynamic>? feedPage;
      final List<Map<String, dynamic>> response;
      if (usesSnapshot) {
        feedPage = Map<String, dynamic>.from(
            await _client.rpc('community_feed_page', params: {
          'p_sort': sort,
          'p_topic': topic,
          'p_lat': latitude,
          'p_lng': longitude,
          'p_snapshot': append ? _feedSnapshot : null,
          'p_after': append ? _feedAfter : 0,
        }));
        response = List<Map<String, dynamic>>.from(feedPage['items']);
      } else {
        response = await query
            .order('created_at', ascending: false)
            .order('id', ascending: false)
            .limit(40);
      }

      int count(dynamic value) => value is List && value.isNotEmpty
          ? ((value.first as Map)['count'] as num?)?.toInt() ?? 0
          : 0;
      final nextLikes = <String>{};
      final user = _client.auth.currentUser;
      if (user != null && response.isNotEmpty) {
        final ownLikes = await _client
            .from('travel_post_likes')
            .select('post_id')
            .eq('user_id', user.id)
            .inFilter('post_id', response.map((row) => row['id']).toList());
        nextLikes.addAll(ownLikes.map((row) => row['post_id'].toString()));
      }
      if (_disposed || request != _postsRequest) return;
      if (!append) {
        likeCounts.clear();
        commentCounts.clear();
        likedPosts.clear();
        _posts.clear();
      }
      _feedSnapshot = feedPage?['snapshot'] as String?;
      _feedAfter = (feedPage?['next'] as num?)?.toInt() ?? 0;
      if (response.isNotEmpty) _postCursor = response.last;
      hasMorePosts = feedPage?['has_more'] as bool? ?? response.length == 40;
      for (final row in response) {
        likeCounts[row['id'].toString()] = count(row['travel_post_likes']);
        commentCounts[row['id'].toString()] =
            count(row['travel_post_comments']);
      }
      likedPosts.addAll(nextLikes);
      final ids = _posts.map((post) => post.id).toSet();
      _posts.addAll(response
          .map(CommunityPost.fromMap)
          .where((post) => ids.add(post.id)));
    } catch (e) {
      if (_disposed || request != _postsRequest) return;
      debugPrint('❌ loadPosts 에러: $e');
      errorMessage =
          e is PostgrestException && e.message.contains('FEED_SNAPSHOT_EXPIRED')
              ? '조회 시간이 만료됐어요. 새로고침하면 최신 게시물을 볼 수 있어요.'
              : '게시물을 불러오지 못했습니다.';
    } finally {
      if (!_disposed && request == _postsRequest) {
        isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMyMarkers() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    isLoadingMarkers = true;
    notifyListeners();
    try {
      final response = await _client
          .from('user_markers')
          .select('id, title, address, keyword, lat, lng, marker_image_path')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);
      _myMarkers
        ..clear()
        ..addAll(
          (response as List).map(
            (data) => CommunityMarker.fromMap(data as Map<String, dynamic>),
          ),
        );
    } catch (_) {
      errorMessage = '내 마커를 불러오지 못했습니다.';
    } finally {
      isLoadingMarkers = false;
      notifyListeners();
    }
  }

  Future<bool> createPost({
    required String title,
    required String content,
    String? destination,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      errorMessage = '로그인 후 여행 이야기를 작성할 수 있습니다.';
      notifyListeners();
      return false;
    }

    try {
      await _client.from('travel_posts').insert({
        'author_id': user.id,
        'title': title.trim(),
        'content': content.trim(),
        'destination':
            destination?.trim().isEmpty ?? true ? null : destination!.trim(),
      });
      await loadPosts();
      return true;
    } catch (_) {
      errorMessage = '게시물을 등록하지 못했습니다.';
      notifyListeners();
      return false;
    }
  }

  Future<bool> createMarkerPost({
    required CommunityMarker marker,
    String? content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      errorMessage = '로그인 후 마커를 공유할 수 있습니다.';
      notifyListeners();
      return false;
    }

    try {
      final message = content?.trim();
      await _client.from('travel_posts').insert({
        'author_id': user.id,
        'title': marker.title,
        'content': message == null || message.isEmpty
            ? '${marker.title}을(를) 추천합니다.'
            : message,
        'destination': marker.address,
        'marker_id': marker.id,
        'place_title': marker.title,
        'place_address': marker.address,
        'place_category': marker.category,
        'place_lat': marker.latitude,
        'place_lng': marker.longitude,
        'place_image_path': marker.imagePath,
      });
      await loadPosts();
      return true;
    } catch (_) {
      errorMessage = '마커를 게시판에 등록하지 못했습니다.';
      notifyListeners();
      return false;
    }
  }
}
