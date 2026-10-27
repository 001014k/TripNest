import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:fluttertrip/models/community/community_post_model.dart';
import 'package:fluttertrip/services/community/community_nearby_service.dart';

CommunityPost post(String id, {String? address, double? lat, double? lng}) =>
    CommunityPost(
        id: id,
        title: id,
        content: '',
        destination: null,
        authorId: 'author',
        authorNickname: '',
        createdAt: DateTime(2026),
        placeAddress: address,
        placeLatitude: lat,
        placeLongitude: lng);
void main() {
  test(
      'Uses stored coordinates, resolves addresses, caches and skips failed lookups',
      () async {
    var calls = 0;
    final service = CommunityNearbyService(geocode: (address) async {
      calls++;
      if (address == 'unknown') throw StateError('unavailable');
      return const LatLng(37.51, 127);
    });
    final posts = [
      post('near', lat: 37.5, lng: 127),
      post('address', address: '서울 주소'),
      post('far', lat: 33.5, lng: 126.5),
      post('failed', address: 'unknown'),
      post('missing')
    ];
    final distances = await service.distances(posts, const LatLng(37.5, 127));
    expect(distances['near'], 0);
    expect(distances['address'], lessThan(20000));
    expect(distances['far'], greaterThan(20000));
    expect(distances.containsKey('failed'), isFalse);
    expect(distances.containsKey('missing'), isFalse);
    expect(calls, 2);
    await service.distances([posts[1]], const LatLng(37.6, 127));
    expect(calls, 2);
  });
}
