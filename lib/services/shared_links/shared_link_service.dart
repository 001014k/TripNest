import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/shared_links/link_place_preview_model.dart';
import '../../models/shared_links/shared_link_model.dart';

class SharedLinkService {
  SharedLinkService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;
  final SupabaseClient _client;

  Future<void> saveSharedLinkPlace(
    String url,
    String platform,
    LinkPlacePreview placePreview,
  ) async {
    await saveSharedLinkPlaces(url, platform, [placePreview]);
  }

  Future<void> saveSharedLinkPlaces(
      String url, String platform, List<LinkPlacePreview> places) async {
    if (_client.auth.currentUser == null) throw StateError('로그인이 필요합니다');
    await _client.rpc('save_shared_link_places_atomic', params: {
      'p_url': url,
      'p_platform': platform,
      'p_places': [
        for (final place in places)
          {
            'title': place.title,
            'address': place.address,
            'latitude': place.latitude,
            'longitude': place.longitude,
          }
      ],
    });
  }

  Future<List<SharedLinkModel>> loadSharedLinks() => loadSharedLinksPage();

  Future<List<SharedLinkModel>> loadSharedLinksPage(
      {SharedLinkModel? before, String search = '', String? platform}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw StateError('로그인이 필요합니다.');
    var query = _client.from('shared_links').select().eq('user_id', user.id);
    final filters = <String>[];
    if (search.trim().isNotEmpty) {
      final escaped = search
          .trim()
          .replaceAll('\\', '\\\\')
          .replaceAll('"', '\\"')
          .replaceAll('%', r'\%')
          .replaceAll('_', r'\_')
          .replaceAll('*', r'\*');
      filters.add(
          'or(place_title.ilike."%$escaped%",place_address.ilike."%$escaped%",url.ilike."%$escaped%")');
    }
    if (platform != null) query = query.eq('platform', platform);
    if (before != null) {
      final date = before.createdAt.toIso8601String();
      filters.add(
          'or(created_at.lt.$date,and(created_at.eq.$date,id.lt.${before.id}))');
    }
    if (filters.isNotEmpty) query = query.or('and(${filters.join(',')})');
    final response = await query
        .order('created_at', ascending: false)
        .order('id', ascending: false)
        .limit(40);
    return response.map(SharedLinkModel.fromMap).toList();
  }

  /// 하나의 공유 원본 URL에서 추출된 모든 장소를 반환합니다.
  /// 원본 게시물 하나에 여러 장소가 있을 수 있으며 장소별로 한 행씩 저장합니다.
  Future<List<SharedLinkModel>> loadSharedLinkPlaces(String url) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final response = await _client
        .from('shared_links')
        .select()
        .eq('user_id', user.id)
        .eq('url', url)
        .order('created_at', ascending: true);

    return response.map((e) => SharedLinkModel.fromMap(e)).toList();
  }

  Future<void> deleteSharedLink(String id) async {
    final res =
        await _client.from('shared_links').delete().eq('id', id).select();

    if (res.isEmpty) {
      throw Exception('링크 삭제에 실패했습니다.');
    }
  }

  Future<void> deleteSharedLinkGroup(String url) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('로그인이 필요합니다');

    final response = await _client
        .from('shared_links')
        .delete()
        .eq('user_id', user.id)
        .eq('url', url)
        .select('id');

    if (response.isEmpty) {
      throw Exception('링크 삭제에 실패했습니다.');
    }
  }

  Future<bool> doesPlaceExist(
    String url,
    LinkPlacePreview placePreview,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    final address = placePreview.address.trim();

    if (address.isNotEmpty) {
      final response = await _client
          .from('shared_links')
          .select('id')
          .eq('user_id', user.id)
          .eq('url', url)
          .eq('place_address', address)
          .limit(1);

      return response.isNotEmpty;
    }

    final response = await _client
        .from('shared_links')
        .select('id')
        .eq('user_id', user.id)
        .eq('url', url)
        .eq('place_title', placePreview.title.trim())
        .limit(1);

    return response.isNotEmpty;
  }

  Future<bool> doesLinkExist(String url) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      return false;
    }

    final response = await _client
        .from('shared_links')
        .select('id')
        .eq('user_id', user.id)
        .eq('url', url)
        .limit(1);

    return response.isNotEmpty;
  }

  Future<void> saveSharedLink(
    String url,
    String platform, {
    LinkPlacePreview? placePreview,
  }) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final existing = await _client
          .from('shared_links')
          .select()
          .eq('user_id', user.id)
          .eq('url', url)
          .limit(1)
          .maybeSingle();

      if (existing != null) {
        if (placePreview != null && existing['place_address'] == null) {
          await _client.from('shared_links').update({
            'place_title': placePreview.title,
            'place_address': placePreview.address,
            'place_latitude': placePreview.latitude,
            'place_longitude': placePreview.longitude,
          }).eq('id', existing['id']);
        }

        debugPrint('이미 저장된 링크입니다: $url');
        return;
      }

      final data = {
        'user_id': user.id,
        'url': url,
        'platform': platform,
        'created_at': DateTime.now().toIso8601String(),
        'place_title': placePreview?.title,
        'place_address': placePreview?.address,
        'place_latitude': placePreview?.latitude,
        'place_longitude': placePreview?.longitude,
      };

      final response = await _client.from('shared_links').insert(data).select();

      if (response.isEmpty) {
        throw Exception('링크 저장에 실패했습니다.');
      }

      debugPrint('링크 저장 성공 ($platform): $url');
    } catch (e) {
      debugPrint('링크 저장 중 예외 발생: $e');
      rethrow;
    }
  }
}
