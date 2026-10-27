import '../../services/community/story_saved_places.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../services/places/geocoding_service.dart';
import '../../navigation/app_page_route.dart';
import '../../views/markers/markercreationscreen_view.dart';
import '../../models/community/community_post_model.dart';
import '../../viewmodels/map/mapsample_viewmodel.dart';

Future<bool> createMarkerFromStory(BuildContext context, CommunityPost post) async {
    final map = context.read<MapSampleViewModel?>();
    if (map == null) return false;
    void message(String text) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
    try {
      final lat = post.placeLatitude;
      final lng = post.placeLongitude;
      final position = lat != null && lng != null && lat.isFinite && lng.isFinite &&
              lat.abs() <= 90 && lng.abs() <= 180
          ? LatLng(lat, lng)
          : await const GeocodingService().findCoordinates(post.placeAddress ?? '')
              .timeout(const Duration(seconds: 10));
      if (!context.mounted) return false;
      if (position == null) {
        message('장소 위치를 찾지 못했어요. 주소를 확인해주세요.');
        return false;
      }
      final source = Marker(
        markerId: MarkerId('community-place-${post.id}'),
        position: position,
        infoWindow: InfoWindow(title: post.placeTitle ?? post.title),
      );
      if (await map.findSavedPlace(source) != null) {
        message('이미 내 지도에 저장된 장소예요.');
        return true;
      }
      if (!context.mounted) return false;
      final result = await Navigator.of(context).push<Map<String, dynamic>>(
        AppPageRoute(motion: AppMotion.editor, builder: (_) => MarkerCreationScreen(
          initialLatLng: position,
          initialTitle: post.placeTitle ?? post.title,
          initialAddress: post.placeAddress,
        )),
      );
      if (!context.mounted || result == null) return false;
      final title = result['title'] as String?;
      final keyword = result['keyword'] as String?;
      if (title == null || title.trim().isEmpty || keyword == null) {
        message('마커 정보를 확인해주세요.');
        return false;
      }
      // Recheck after the editor, including a name changed by the user.
      final existing = await map.findSavedPlace(source) ??
          await map.findSavedPlace(source.copyWith(infoWindowParam: InfoWindow(title: title)));
      if (!context.mounted) return false;
      if (existing != null) {
        message('이미 내 지도에 저장된 장소예요.');
        return true;
      }
      final saved = await map.addMarker(
        title: title,
        snippet: result['snippet'] as String?,
        position: position,
        keyword: keyword,
        address: result['address'] as String? ?? post.placeAddress ?? '',
        listId: result['listId'] as String?,
        onTapCallback: (id) => map.onMarkerTapped(id),
      );
      if (!context.mounted) return false;
      message(saved ? '내 지도에 마커를 저장했습니다.' : '저장하지 못했어요. 다시 시도해주세요.');
      if (saved) await StorySavedPlaces.refresh();
      return saved;
    } catch (_) {
      message('장소 정보를 확인하지 못했어요. 로그인 상태와 네트워크를 확인해주세요.');
    }
    return false;
}
