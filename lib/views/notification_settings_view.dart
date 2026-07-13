import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_design.dart';
import '../viewmodels/notification_settings_viewmodel.dart';

class NotificationSettingsView extends StatefulWidget {
  const NotificationSettingsView({super.key});

  @override
  State<NotificationSettingsView> createState() => _NotificationSettingsViewState();
}

class _NotificationSettingsViewState extends State<NotificationSettingsView> {
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NotificationSettingsViewModel()..loadSettings(),
      child: Consumer<NotificationSettingsViewModel>(
        builder: (context, viewModel, _) {
          return Scaffold(
            backgroundColor: AppDesign.primaryBg,
            appBar: AppBar(
              backgroundColor: AppDesign.primaryBg,
              elevation: 0,
              title: Text('알림 설정', style: AppDesign.headingMedium),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppDesign.primaryText),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: viewModel.isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
              padding: const EdgeInsets.all(AppDesign.spacing20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionLabel(label: '푸시 알림'),
                  const SizedBox(height: AppDesign.spacing12),
                  _NotificationTile(
                    title: '새 마커 알림',
                    subtitle: '친구가 마커를 공유했을 때',
                    value: viewModel.pushNewMarker,
                    onChanged: (val) => viewModel.updatePushSetting('new_marker', val),
                  ),
                  _NotificationTile(
                    title: '리스트 업데이트',
                    subtitle: '팔로잉 리스트에 변경사항이 있을 때',
                    value: viewModel.pushListUpdate,
                    onChanged: (val) => viewModel.updatePushSetting('list_update', val),
                  ),
                  _NotificationTile(
                    title: '친구 요청',
                    subtitle: '새로운 친구 요청이 왔을 때',
                    value: viewModel.pushFriendRequest,
                    onChanged: (val) => viewModel.updatePushSetting('friend_request', val),
                  ),

                  const SizedBox(height: AppDesign.spacing32),
                  _SectionLabel(label: '이메일 알림'),
                  const SizedBox(height: AppDesign.spacing12),
                  _NotificationTile(
                    title: '주간 여행 소식',
                    subtitle: '인기 여행지 및 업데이트',
                    value: viewModel.emailWeekly,
                    onChanged: (val) => viewModel.updateEmailSetting('weekly', val),
                  ),
                  _NotificationTile(
                    title: '보안 알림',
                    subtitle: '계정 로그인 및 변경사항',
                    value: viewModel.emailSecurity,
                    onChanged: (val) => viewModel.updateEmailSetting('security', val),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppDesign.caption.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _NotificationTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDesign.spacing12),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(color: AppDesign.borderColor),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDesign.spacing20,
          vertical: AppDesign.spacing8,
        ),
        title: Text(title, style: AppDesign.bodyMedium),
        subtitle: Text(subtitle, style: AppDesign.caption),
        value: value,
        activeColor: AppDesign.travelBlue,
        onChanged: onChanged,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        ),
      ),
    );
  }
}