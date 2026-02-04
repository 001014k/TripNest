import 'package:hive/hive.dart';

part 'cached_photo_url.g.dart';

@HiveType(typeId: 3)
class CachedPhotoUrl extends HiveObject {
  @HiveField(0)
  String cacheKey = '';

  @HiveField(1)
  String photoUrl = '';

  @HiveField(2)
  DateTime cachedAt;

  CachedPhotoUrl({
    String? cacheKey,
    String? photoUrl,
    DateTime? cachedAt,
  })  : cacheKey = cacheKey ?? '',
        photoUrl = photoUrl ?? '',
        cachedAt = cachedAt ?? DateTime.now();

  bool get isValid => DateTime.now().difference(cachedAt).inHours < 24;
}