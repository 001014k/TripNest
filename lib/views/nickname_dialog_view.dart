import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../design/app_design.dart';
import '../viewmodels/nickname_dialog_viewmodel.dart';

class NicknameSetupPage extends StatelessWidget {
  final String userId;
  final FocusNode _nicknameFocusNode = FocusNode();

  NicknameSetupPage({Key? key, required this.userId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NicknameDialogViewModel(userId: userId),
      child: Consumer<NicknameDialogViewModel>(
        builder: (context, vm, _) {
          return WillPopScope(
            onWillPop: () async => false,
            child: Scaffold(
              resizeToAvoidBottomInset: true,
              backgroundColor: AppDesign.primaryBg,
              body: Container(
                decoration: const BoxDecoration(
                  gradient: AppDesign.backgroundGradient,
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      // 프로그레스 인디케이터
                      _buildProgressHeader(),

                      // 메인 컨텐츠
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(AppDesign.spacing24),
                          child: Column(
                            children: [
                              const SizedBox(height: AppDesign.spacing32),

                              // 아바타 및 환영 메시지
                              _buildWelcomeSection(),

                              const SizedBox(height: AppDesign.spacing40),

                              // 닉네임 설정 카드
                              _buildNicknameCard(context, vm),

                              const SizedBox(height: AppDesign.spacing24),

                              // 가이드라인 섹션
                              _buildGuidelineSection(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('닉네임 설정', style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText)),
              Text('2/2', style: AppDesign.bodyMedium.copyWith(color: AppDesign.travelBlue, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 1.0, // 100% 완료 표시
            backgroundColor: AppDesign.borderColor,
            valueColor: const AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Column(
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppDesign.primaryGradient,
            shape: BoxShape.circle,
            boxShadow: AppDesign.glowShadow,
          ),
          child: const Icon(
            Icons.person_outline,
            size: 48,
            color: AppDesign.whiteText,
          ),
        ),
        const SizedBox(height: AppDesign.spacing24),
        Text(
          '거의 다 완료됐어요! 🎉',
          style: AppDesign.headingLarge.copyWith(
            color: AppDesign.primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesign.spacing12),
        Text(
          '마지막으로 다른 여행자들이 볼 수 있는\n닉네임을 설정해주세요',
          style: AppDesign.bodyLarge.copyWith(
            color: AppDesign.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNicknameCard(BuildContext context, NicknameDialogViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '닉네임',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.primaryText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),

          // 닉네임 입력 필드
          Container(
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              border: Border.all(
                color: _nicknameFocusNode.hasFocus
                    ? AppDesign.travelPurple
                    : (vm.error != null
                        ? AppDesign.sunsetGradientStart
                        : AppDesign.borderColor),
                width: _nicknameFocusNode.hasFocus || vm.error != null ? 2 : 1,
              ),
            ),
            child: TextField(
              focusNode: _nicknameFocusNode,
              autofocus: true,
              onChanged: (val) => vm.nickname = val,
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.primaryText,
              ),
              decoration: InputDecoration(
                hintText: '2-10자로 입력해주세요',
                hintStyle: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.subtleText,
                ),
                prefixIcon: Container(
                  margin: const EdgeInsets.all(AppDesign.spacing12),
                  decoration: BoxDecoration(
                    color: AppDesign.travelPurple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppDesign.spacing8),
                  ),
                  child: const Icon(
                    Icons.badge_outlined,
                    color: AppDesign.travelPurple,
                    size: 20,
                  ),
                ),
                suffixIcon: _buildSuffixIcon(vm),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing16,
                  vertical: AppDesign.spacing16,
                ),
                errorText: null, // 에러는 별도로 표시
              ),
            ),
          ),

          // 닉네임 상태 메시지
          if (vm.nicknameStatusMessage != null) _buildStatusMessage(vm),

          // 에러 메시지
          if (vm.error != null) _buildErrorMessage(vm.error!),

          const SizedBox(height: AppDesign.spacing32),

          // 저장 버튼
          _buildSaveButton(context, vm),
        ],
      ),
    );
  }

  Widget _buildSuffixIcon(NicknameDialogViewModel vm) {
    if (vm.isChecking) {
      return const Padding(
        padding: EdgeInsets.all(AppDesign.spacing12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelPurple),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(AppDesign.spacing8),
      decoration: BoxDecoration(
        color: vm.nickname.trim().isEmpty
            ? AppDesign.borderColor
            : AppDesign.travelPurple,
        borderRadius: BorderRadius.circular(AppDesign.spacing8),
      ),
      child: IconButton(
        icon: Icon(
          Icons.check,
          color: vm.nickname.trim().isEmpty
              ? AppDesign.subtleText
              : AppDesign.whiteText,
          size: 20,
        ),
        onPressed: vm.nickname.trim().isEmpty || vm.isSaving
            ? null
            : () => vm.checkNicknameAvailability(),
      ),
    );
  }

  Widget _buildStatusMessage(NicknameDialogViewModel vm) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDesign.spacing12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: vm.isNicknameAvailable
                  ? AppDesign.travelGreen.withOpacity(0.1)
                  : AppDesign.sunsetGradientStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.spacing4),
            ),
            child: Icon(
              vm.isNicknameAvailable ? Icons.check_circle : Icons.error,
              color: vm.isNicknameAvailable
                  ? AppDesign.travelGreen
                  : AppDesign.sunsetGradientStart,
              size: 16,
            ),
          ),
          const SizedBox(width: AppDesign.spacing8),
          Expanded(
            child: Text(
              vm.nicknameStatusMessage!,
              style: AppDesign.caption.copyWith(
                color: vm.isNicknameAvailable
                    ? AppDesign.travelGreen
                    : AppDesign.sunsetGradientStart,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage(String error) {
    return Padding(
      padding: const EdgeInsets.only(top: AppDesign.spacing12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppDesign.sunsetGradientStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppDesign.spacing4),
            ),
            child: const Icon(
              Icons.error_outline,
              color: AppDesign.sunsetGradientStart,
              size: 16,
            ),
          ),
          const SizedBox(width: AppDesign.spacing8),
          Expanded(
            child: Text(
              error,
              style: AppDesign.caption.copyWith(
                color: AppDesign.sunsetGradientStart,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton(BuildContext context, NicknameDialogViewModel vm) {
    final isEnabled =
        vm.nickname.trim().isNotEmpty && !vm.isSaving && vm.isNicknameAvailable;

    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: isEnabled
            ? AppDesign.primaryGradient
            : LinearGradient(
                colors: [
                  AppDesign.borderColor,
                  AppDesign.borderColor,
                ],
              ),
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: isEnabled ? AppDesign.glowShadow : null,
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor:
              isEnabled ? AppDesign.whiteText : AppDesign.subtleText,
          padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
        onPressed: isEnabled
            ? () async {
                final success = await vm.saveNickname();
                if (success) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/home',
                    (route) => false,
                  );
                }
              }
            : null,
        child: vm.isSaving
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppDesign.whiteText,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.save_outlined, size: 20),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    '저장하고 시작하기',
                    style: AppDesign.bodyMedium.copyWith(
                      color: isEnabled
                          ? AppDesign.whiteText
                          : AppDesign.subtleText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGuidelineSection() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg.withOpacity(0.7),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(
          color: AppDesign.borderColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  color: AppDesign.travelBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesign.spacing8),
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppDesign.travelBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Text(
                '닉네임 가이드라인',
                style: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.primaryText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing16),
          _buildGuidelineItem('• 2-10자 이내로 설정해주세요'),
          _buildGuidelineItem('• 한글, 영문, 숫자 사용 가능합니다'),
          _buildGuidelineItem('• 다른 사용자와 중복될 수 없습니다'),
          _buildGuidelineItem('• 나중에 설정에서 변경 가능합니다'),
        ],
      ),
    );
  }

  Widget _buildGuidelineItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesign.spacing4),
      child: Text(
        text,
        style: AppDesign.caption.copyWith(
          color: AppDesign.secondaryText,
          height: 1.4,
        ),
      ),
    );
  }
}
