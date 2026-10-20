import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../design/app_design.dart'; // 디자인 시스템 import

class ForgotPasswordView extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  ForgotPasswordView({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ForgotPasswordViewModel(),
      child: Consumer<ForgotPasswordViewModel>(
        builder: (context, viewModel, child) {
          return Scaffold(
            backgroundColor: AppDesign.primaryBg,
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppDesign.backgroundGradient,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    // 커스텀 앱바
                    _buildCustomAppBar(context),

                    // 스크롤 가능한 메인 컨텐츠
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(AppDesign.spacing24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: AppDesign.spacing40),

                            // 일러스트레이션 섹션
                            _buildIllustration(),

                            const SizedBox(height: AppDesign.spacing32),

                            // 헤더 섹션
                            _buildHeader(),

                            const SizedBox(height: AppDesign.spacing40),

                            // 비밀번호 재설정 폼 카드
                            _buildResetForm(context, viewModel),

                            const SizedBox(height: AppDesign.spacing24),

                            // 도움말 섹션
                            _buildHelpSection(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDesign.spacing16,
        vertical: AppDesign.spacing12,
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppDesign.primaryText,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Text(
            '비밀번호 찾기',
            style: AppDesign.headingMedium.copyWith(
              color: AppDesign.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppDesign.sunsetGradientStart.withValues(alpha: 0.3),
            blurRadius: 32,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: const Icon(
        Icons.lock_reset,
        size: 48,
        color: AppDesign.whiteText,
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          '비밀번호를 잊으셨나요? 🔐',
          style: AppDesign.headingLarge.copyWith(
            color: AppDesign.primaryText,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: AppDesign.spacing12),
        Text(
          '등록하신 이메일 주소로\n비밀번호 재설정 링크를 보내드릴게요',
          style: AppDesign.bodyLarge.copyWith(
            color: AppDesign.secondaryText,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildResetForm(
      BuildContext context, ForgotPasswordViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing32),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        children: [
          // 이메일 입력 필드
          _buildEmailField(),

          const SizedBox(height: AppDesign.spacing32),

          // 재설정 버튼
          _buildResetButton(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '이메일 주소',
          style: AppDesign.bodyMedium.copyWith(
            color: AppDesign.primaryText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDesign.spacing8),
        Container(
          decoration: BoxDecoration(
            color: AppDesign.lightGray,
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            border: Border.all(
              color: _emailFocusNode.hasFocus
                  ? AppDesign.travelOrange
                  : AppDesign.borderColor,
              width: _emailFocusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.primaryText,
            ),
            decoration: InputDecoration(
              hintText: 'example@email.com',
              hintStyle: AppDesign.bodyMedium.copyWith(
                color: AppDesign.subtleText,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(AppDesign.spacing12),
                decoration: BoxDecoration(
                  color: AppDesign.travelOrange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesign.spacing8),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: AppDesign.travelOrange,
                  size: 20,
                ),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppDesign.spacing16,
                vertical: AppDesign.spacing16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResetButton(
      BuildContext context, ForgotPasswordViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppDesign.travelOrange.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
            spreadRadius: -8,
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: AppDesign.whiteText,
          padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
          ),
        ),
        onPressed: viewModel.isLoading
            ? null
            : () async {
                String email = _emailController.text.trim();
                String? errorMessage =
                    await viewModel.sendPasswordResetEmail(email);

                if (errorMessage == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.mark_email_read_outlined,
                            color: AppDesign.whiteText,
                            size: 20,
                          ),
                          const SizedBox(width: AppDesign.spacing8),
                          Expanded(
                            child: Text(
                              '비밀번호 재설정 이메일을 보냈습니다.',
                              style: AppDesign.bodyMedium.copyWith(
                                color: AppDesign.whiteText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppDesign.travelGreen,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusSmall),
                      ),
                      margin: const EdgeInsets.all(AppDesign.spacing16),
                    ),
                  );
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } else {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppDesign.whiteText,
                            size: 20,
                          ),
                          const SizedBox(width: AppDesign.spacing8),
                          Expanded(
                            child: Text(
                              errorMessage,
                              style: AppDesign.bodyMedium.copyWith(
                                color: AppDesign.whiteText,
                              ),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: AppDesign.sunsetGradientStart,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusSmall),
                      ),
                      margin: const EdgeInsets.all(AppDesign.spacing16),
                    ),
                  );
                }
              },
        child: viewModel.isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppDesign.whiteText),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.send_outlined, size: 20),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    '재설정 이메일 보내기',
                    style: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.whiteText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        border: Border.all(
          color: AppDesign.borderColor.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  color: AppDesign.travelBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesign.spacing8),
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppDesign.travelBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Expanded(
                child: Text(
                  '도움이 필요하신가요?',
                  style: AppDesign.bodyMedium.copyWith(
                    color: AppDesign.primaryText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            '• 이메일이 도착하지 않았다면 스팸함을 확인해주세요\n• 입력하신 이메일이 가입 시 사용한 주소인지 확인해주세요\n• 문제가 지속되면 고객지원팀에 문의해주세요',
            style: AppDesign.caption.copyWith(
              color: AppDesign.secondaryText,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}
