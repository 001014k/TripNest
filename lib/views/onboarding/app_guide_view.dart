import '../../widgets/onboarding/screen_guide_target.dart';
import 'package:flutter/material.dart';
import '../../models/onboarding/guide_topic.dart';
import '../../navigation/app_page_route.dart';
import '../../navigation/app_tab_shell.dart';
import 'onboarding_view.dart';

class AppGuideView extends StatelessWidget {
  const AppGuideView({super.key});
  static const icons = [
    Icons.location_on_outlined,
    Icons.link,
    Icons.people_outline,
    Icons.calendar_today_outlined
  ];
  static void showTopic(BuildContext context, int index) {
    final topic = GuideTopic.topics[index];
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (sheetContext) => SafeArea(
            child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Text(topic.title,
                                style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700))),
                        IconButton(
                            tooltip: '닫기',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: const Icon(Icons.close))
                      ]),
                      const SizedBox(height: 12),
                      for (var i = 0; i < topic.steps.length; i++)
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                      radius: 14,
                                      backgroundColor: const Color(0xFFF0F1F3),
                                      child: Text('${i + 1}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF222222)))),
                                  const SizedBox(width: 12),
                                  Expanded(
                                      child: Text(topic.steps[i],
                                          style: const TextStyle(
                                              fontSize: 15, height: 1.6))),
                                ])),
                      const SizedBox(height: 16),
                      SizedBox(
                          width: double.infinity,
                          child: FilledButton(
                              onPressed: () {
                                Navigator.pop(sheetContext);
                                if (AppTabController.routes
                                    .contains(topic.route)) {
                                  AppTabController.open(context, topic.route);
                                } else {
                                  Navigator.pushNamed(context, topic.route);
                                }
                              },
                              child: Text(topic.action))),
                    ]))));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFFAFAFA),
        appBar: AppBar(
            title: const Text('앱 사용 가이드'),
            centerTitle: true,
            backgroundColor: const Color(0xFFFAFAFA)),
        body: SafeArea(
            child: ListView(padding: const EdgeInsets.all(24), children: [
          const Text('TripNest, 이렇게 사용해요',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          const Text('필요한 순간에, 필요한 만큼',
              style: TextStyle(color: Color(0xFF77777D))),
          const SizedBox(height: 28),
          for (var i = 0; i < GuideTopic.topics.length; i++)
            Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                        side: const BorderSide(color: Color(0xFFE8E8EB))),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 14),
                        leading: Icon(icons[i],
                            size: 28, color: const Color(0xFF222222)),
                        title: Text(GuideTopic.topics[i].title,
                            style:
                                const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(GuideTopic.topics[i].subtitle,
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF77777D)))),
                        trailing: const Icon(Icons.chevron_right, size: 20),
                        onTap: () => showTopic(context, i)))),
          const SizedBox(height: 24),
          const Text('기능별 화면 안내',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          const Text('필요한 설명만 다시 확인해보세요.',
              style: TextStyle(color: Color(0xFF77777D))),
          const SizedBox(height: 12),
          for (final guide in FeatureGuide.values)
            ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.tips_and_updates_outlined),
                title: Text(guide.title, style: const TextStyle(fontSize: 14)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => ScreenGuide.start(context, only: guide)),
          const SizedBox(height: 14),
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: const Color(0xFFF0F1F3),
                  borderRadius: BorderRadius.circular(18)),
              child: Column(children: [
                const Text('설명이 다시 필요하신가요?'),
                const SizedBox(height: 14),
                SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                        onPressed: () => Navigator.push(
                            context,
                            AppPageRoute(
                                builder: (introContext) => OnboardingView(
                                    onFinished: () =>
                                        Navigator.pop(introContext)))),
                        child: const Text('첫 실행 소개 다시 보기'))),
              ])),
          const SizedBox(height: 20),
          const Text('MY에서 언제든 확인할 수 있어요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Color(0xFF77777D))),
        ])),
      );
}
