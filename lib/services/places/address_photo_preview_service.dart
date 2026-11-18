import 'place_lookup_repository.dart';
import 'place_photo_resolver.dart';
import '../infrastructure/async_ttl_cache.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;

import '../../models/places/cached_photo_url.dart';

class AddressPhotoPreviewService {
  const AddressPhotoPreviewService(
      {http.Client? client, PlacePhotoResolver? resolver})
      : _client = client,
        _resolver = resolver;
  final PlacePhotoResolver? _resolver;
  final http.Client? _client;

  static final _photos = AsyncTtlCache<String, List<String>>(
      ttl: const Duration(minutes: 45), isEmpty: (value) => value.isEmpty);

  Future<List<String>> loadPhotos(String address, String? title) => _client ==
          null
      ? _photos.get(cacheKey(address, title), () => _loadPhotos(address, title))
      : _loadPhotos(address, title);

  String cacheKey(String address, String? title) {
    final addr = address.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
    final ttl = title?.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_') ??
        'no_title';
    return 'gateway-v1|$addr|$ttl';
  }

  Future<String?> load(String address, String? title) async {
    final key = cacheKey(address, title);
    final box = Hive.box<CachedPhotoUrl>('photo_urls');
    final cached = box.get(key);
    if (cached != null && cached.isValid) return cached.photoUrl;

    final photos = await loadPhotos(address, title);
    if (photos.isEmpty) return null;
    final photo =
        await (_resolver ?? PlacePhotoResolver.shared).resolve(photos.first);
    await box.put(key, CachedPhotoUrl(cacheKey: key, photoUrl: photo));
    return photo;
  }

  Future<List<String>> _loadPhotos(String address, String? title) async {
    if (address.trim().isEmpty && (title?.trim().isEmpty ?? true)) return [];
    final query =
        title != null && title.isNotEmpty ? '$title, $address' : address;
    final repository = _client == null
        ? PlaceLookupRepository.shared
        : PlaceLookupRepository(client: _client);
    final place =
        await repository.lookup(query, PlaceLookupRepository.photoFields);
    final urls = PlaceLookupRepository.photoUrls(place);
    // 사진 참조만 반환하고, 사진을 실제로 표시할 때 미디어 주소를 조회합니다.
    return urls;
  }

  Future<void> clear(String address, String? title) async {
    _photos.invalidate(cacheKey(address, title));
    await Hive.box<CachedPhotoUrl>('photo_urls')
        .delete(cacheKey(address, title));
  }
}
