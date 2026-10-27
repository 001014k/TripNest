import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/notifications/notification_settings_viewmodel.dart';
import '../../widgets/navigation/tripnest_navigation.dart';

class NotificationSettingsView extends StatelessWidget {
  const NotificationSettingsView({super.key});

  @override
  Widget build(BuildContext context) => ChangeNotifierProvider(
        create: (_) => NotificationSettingsViewModel()..loadSettings(),
        child: Consumer<NotificationSettingsViewModel>(
          builder: (context, vm, _) => Scaffold(
            backgroundColor: const Color(0xFFFCFCFD),
            body: SafeArea(
                child: Column(children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
                child: TripNestHeader(
                    onBack: () => Navigator.pop(context),
                    trailing: const SizedBox.shrink()),
              ),
              Expanded(
                  child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 6),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('알림 설정',
                                              style: TextStyle(
                                                  fontSize: 30,
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.black,
                                                  letterSpacing: -1,
                                                  height: 1.3)),
                                          SizedBox(height: 8),
                                          Text('필요한 여행 소식만 받아보세요.',
                                              style: TextStyle(
                                                  fontSize: 15,
                                                  color: _secondary,
                                                  height: 1.5)),
                                        ])),
                                const SizedBox(height: 28),
                                const _SectionLabel(
                                    label: '푸시 알림',
                                    icon: Icons.notifications_none_rounded),
                                const SizedBox(height: 14),
                                if (vm.isLoading)
                                  const _NotificationGroup(children: [
                                    _NotificationSkeletonRow(),
                                    _NotificationSkeletonRow(),
                                    _NotificationSkeletonRow(),
                                  ])
                                else _NotificationGroup(children: [
                                  _NotificationTile(
                                      title: '새 마커 알림',
                                      subtitle: '친구가 마커를 공유했을 때',
                                      icon: Icons.location_on_outlined,
                                      value: vm.pushNewMarker,
                                      onChanged: (value) =>
                                          vm.updatePushSetting(
                                              'new_marker', value)),
                                  _NotificationTile(
                                      title: '리스트 업데이트',
                                      subtitle: '함께 쓰는 리스트가 변경됐을 때',
                                      icon: Icons.format_list_bulleted_rounded,
                                      value: vm.pushListUpdate,
                                      onChanged: (value) =>
                                          vm.updatePushSetting(
                                              'list_update', value)),
                                  _NotificationTile(
                                      title: '친구 요청',
                                      subtitle: '새로운 친구 요청이 왔을 때',
                                      icon: Icons.person_add_alt_outlined,
                                      value: vm.pushFriendRequest,
                                      onChanged: (value) =>
                                          vm.updatePushSetting(
                                              'friend_request', value)),
                                ]),
                                const SizedBox(height: 28),
                                if (vm.pushConnectionMessage != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 20),
                                    child: Text(vm.pushConnectionMessage!,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: _secondary,
                                            height: 1.5)),
                                  ),
                                const _SectionLabel(
                                    label: '계정 보안 알림',
                                    icon: Icons.shield_outlined),
                                const SizedBox(height: 14),
                                if (vm.isLoading)
                                  const _NotificationGroup(children: [_NotificationSkeletonRow()])
                                else _NotificationGroup(children: [
                                  _NotificationTile(
                                      title: '보안 알림',
                                      subtitle: vm.securityEmailDescription,
                                      icon: Icons.verified_user_outlined,
                                      value: vm.emailSecurity,
                                      onChanged: (value) =>
                                          vm.updateEmailSetting(
                                              'security', value)),
                                ]),
                                const SizedBox(height: 16),
                                const Padding(
                                    padding:
                                        EdgeInsets.symmetric(horizontal: 14),
                                    child: Text('알림 설정은 변경 즉시 적용돼요.',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: _secondary,
                                            height: 1.5))),
                              ]),
                        )),
            ])),
          ),
        ),
      );
}

const _secondary = Color(0xFF777B86);

class _SectionLabel extends StatelessWidget {
  final String label;
  final IconData icon;
  const _SectionLabel({required this.label, required this.icon});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(children: [
          Icon(icon, size: 25, color: Colors.black),
          const SizedBox(width: 13),
          Text(label,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                  letterSpacing: -.4)),
        ]),
      );
}

class _NotificationGroup extends StatelessWidget {
  final List<Widget> children;
  const _NotificationGroup({required this.children});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: const Color(0xFFECEDEF)),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x04000000),
                  blurRadius: 18,
                  offset: Offset(0, 5))
            ]),
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0)
              const Divider(height: 1, thickness: .7, color: Color(0xFFE6E7EA)),
            children[i],
          ],
        ]),
      );
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotificationTile(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.value,
      required this.onChanged});
  @override
  Widget build(BuildContext context) => MergeSemantics(
          child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(children: [
          SizedBox(width: 28, child: Icon(icon, size: 27, color: Colors.black)),
          const SizedBox(width: 16),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black,
                        height: 1.3,
                        letterSpacing: -.4)),
                const SizedBox(height: 5),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 12, color: _secondary, height: 1.4)),
              ])),
          const SizedBox(width: 10),
          CupertinoSwitch(
              value: value,
              onChanged: onChanged,
              activeTrackColor: const Color(0xFF101010),
              inactiveTrackColor: const Color(0xFFD9DADD),
              thumbColor: Colors.white),
        ]),
      ));
}

class _NotificationSkeletonRow extends StatefulWidget {
  const _NotificationSkeletonRow();
  @override
  State<_NotificationSkeletonRow> createState() => _NotificationSkeletonRowState();
}

class _NotificationSkeletonRowState extends State<_NotificationSkeletonRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 900));
  late final Animation<double> _opacity = Tween<double>(begin: .4, end: 1).animate(_controller);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _block(double width, double height, {double radius = 6}) => Container(
    width: width, height: height,
    decoration: BoxDecoration(color: const Color(0xFFE8E9EC), borderRadius: BorderRadius.circular(radius)),
  );

  @override
  Widget build(BuildContext context) => Semantics(
    label: '알림 설정 불러오는 중',
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: FadeTransition(opacity: _opacity, child: Row(children: [
        _block(28, 28),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FractionallySizedBox(widthFactor: .6, child: _block(double.infinity, 18)),
          const SizedBox(height: 8),
          _block(double.infinity, 12),
        ])),
        const SizedBox(width: 10),
        _block(51, 31, radius: 20),
      ])),
    ),
  );
}
