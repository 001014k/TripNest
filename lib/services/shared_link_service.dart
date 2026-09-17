import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/link_place_preview_model.dart';
import '../models/shared_link_model.dart';

class SharedLinkService {
  final SupabaseClient _client = Supabase.instance.client;

  Future<void> saveSharedLinkPlace(
    String url,
    String platform,
    LinkPlacePreview placePreview,
  ) async {
    final user = _client.auth.currentUser;

    if (user == null) {
      throw Exception('로그인이 필요합니다');
    }

    try {
      final alreadyExists = await doesPlaceExist(
        url,
        placePreview,
      );

      if (alreadyExists) {
        debugPrint(
          '⚠️ 이미 저장된 장소입니다: '
          '${placePreview.title} | ${placePreview.address}',
        );
        return;
      }

      final data = {
        'user_id': user.id,
        'url': url,
        'platform': platform,
        'created_at': DateTime.now().toIso8601String(),
        'place_title': placePreview.title,
        'place_address': placePreview.address,
        'place_latitude': placePreview.latitude,
        'place_longitude': placePreview.longitude,
      };

      final response = await _client.from('shared_links').insert(data).select();

      if (response.isEmpty) {
        throw Exception('장소 저장에 실패했습니다.');
      }

      debugPrint(
        '✅ 장소 저장 성공: ${placePreview.title}',
      );
    } catch (e) {
      debugPrint(
        '❌ [saveSharedLinkPlace] 오류: $e',
      );
      rethrow;
    }
  }

  Future<List<SharedLinkModel>> loadSharedLinks() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception("로그인이 필요합니다");

    final response = await _client
        .from('shared_links')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    final list = response.map((e) => SharedLinkModel.fromMap(e)).toList();

    return list;
  }

  /// Returns every place extracted from one shared source URL.
  /// A source post can contain more than one place, with one row per place.
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
