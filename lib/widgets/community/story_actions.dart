import '../../services/community/story_saved_places.dart';
import 'package:flutter/material.dart';
import '../places/place_keyword_icon.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/community/community_post_model.dart';
import 'story_marker_flow.dart';

String storyPreferenceKey(String kind) =>
    'stories_${Supabase.instance.client.auth.currentUser?.id ?? 'guest'}_$kind';
Future<Set<String>> followedStoryAuthors() async =>
    (await SharedPreferences.getInstance())
        .getStringList(storyPreferenceKey('following'))
        ?.toSet() ??
    {};
Future<void> setStoryFollowing(String author, bool follow) async {
  final authors = await followedStoryAuthors();
  follow ? authors.add(author) : authors.remove(author);
  await (await SharedPreferences.getInstance())
      .setStringList(storyPreferenceKey('following'), authors.toList());
}

Uri storyMapUri(CommunityPost post) =>
    Uri.https('www.google.com', '/maps/search/', {
      'api': '1',
      'query': post.placeLatitude != null && post.placeLongitude != null
          ? '${post.placeLatitude},${post.placeLongitude}'
          : '${post.placeTitle ?? post.title} ${post.placeAddress ?? post.destination ?? ''}'
    });
Future<void> openStoryMap(BuildContext context, CommunityPost post) async {
  try {
    if (!await launchUrl(storyMapUri(post),
        mode: LaunchMode.externalApplication)) {
      throw StateError('map');
    }
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('지도를 열지 못했습니다. 잠시 후 다시 시도해주세요.')));
    }
  }
}

Future<void> shareStory(BuildContext context, CommunityPost post) async {
  final box = context.findRenderObject() as RenderBox?;
  try {
    await SharePlus.instance.share(ShareParams(
        text:
            '${post.placeTitle ?? post.title}\n${post.content}\n${storyMapUri(post)}',
        sharePositionOrigin:
            box == null ? null : box.localToGlobal(Offset.zero) & box.size));
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('공유를 시작하지 못했습니다. 다시 시도해주세요.')));
    }
  }
}

List<String> storyTags(CommunityPost post) => <String>{
      if (post.placeCategory?.trim().isNotEmpty == true)
        post.placeCategory!.trim(),
      ...RegExp(r'#([^\s#]+)').allMatches(post.content).map((m) => m.group(1)!),
    }.take(5).toList();

class StoryTags extends StatelessWidget {
  const StoryTags({super.key, required this.post, this.showIcons = false});
  final bool showIcons;
  final CommunityPost post;
  @override
  Widget build(BuildContext context) => Wrap(
      spacing: 6,
      runSpacing: 6,
      children: storyTags(post)
          .map((tag) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                  color: const Color(0xfff3f4f5),
                  borderRadius: BorderRadius.circular(10)),
              child: showIcons
                  ? Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(placeKeywordIcon(tag), size: 15,
                          color: const Color(0xff777b84)),
                      const SizedBox(width: 5),
                      Flexible(child: Text(tag,
                          style: const TextStyle(fontSize: 12, color: Color(0xff777b84)))),
                    ])
                  : Text('#$tag',
                      style: const TextStyle(fontSize: 12, color: Color(0xff777b84)))))
          .toList());
}

class StorySaveButton extends StatefulWidget {
  const StorySaveButton({super.key, required this.post, this.color});
  final CommunityPost post;
  final Color? color;
  @override
  State<StorySaveButton> createState() => _StorySaveButtonState();
}

class _StorySaveButtonState extends State<StorySaveButton> {
  bool _busy = false;
  bool _saved = false;
  Future<void> _save() async {
    if (_busy || _saved) return;
    setState(() => _busy = true);
    try {
      final saved = await createMarkerFromStory(context, widget.post);
      if (mounted) setState(() => _saved = saved);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
    valueListenable: StorySavedPlaces.revision,
    builder: (context, _, child) {
      final saved = _saved || StorySavedPlaces.contains(widget.post);
      return IconButton(
      color: widget.color,
      tooltip: saved ? '저장됨' : '저장하기',
      onPressed: _busy || saved || !widget.post.isMarkerShare ? null : _save,
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border, size: 22));
    },
  );

}
