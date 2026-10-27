import 'package:flutter_test/flutter_test.dart';
import 'package:fluttertrip/models/community/community_post_model.dart';
import 'package:fluttertrip/services/community/story_saved_places.dart';

void main() {
  final post = CommunityPost(id: 'post', title: '여행', content: '', destination: null,
    authorId: 'author', authorNickname: '여행자', createdAt: DateTime(2026),
    markerId: 'original', placeTitle: '서울 숲', placeLatitude: 37.54, placeLongitude: 127.04);
  test('Matches original marker or the same named place at the same position', () {
    expect(StorySavedPlaces.matches(post, {'id': 'original'}), isTrue);
    expect(StorySavedPlaces.matches(post, {'id': 'copy', 'title': '서울숲', 'lat': 37.54, 'lng': 127.04}), isTrue);
    expect(StorySavedPlaces.matches(post, {'id': 'copy', 'title': '서울숲', 'lat': 35.0, 'lng': 127.04}), isFalse);
    expect(StorySavedPlaces.matches(post, {'id': 'copy', 'title': '다른 장소', 'lat': 37.54, 'lng': 127.04}), isFalse);
  });
}
