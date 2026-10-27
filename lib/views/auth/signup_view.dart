import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth/signup_viewmodel.dart';
import '../../design/app_design.dart'; // 디자인 시스템 import

class SignupPage extends StatelessWidget {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();

  SignupPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SignupViewModel(),
      child: Consumer<SignupViewModel>(
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: AppDesign.spacing20),

                            // 헤더 섹션
                            _buildHeader(),

                            const SizedBox(height: AppDesign.spacing40),

                            // 회원가입 폼 카드
                            _buildSignupForm(context, viewModel),

                            const SizedBox(height: AppDesign.spacing24),
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
            '회원가입',
            style: AppDesign.headingMedium.copyWith(
              color: AppDesign.primaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '환영합니다! 🌟',
          style: AppDesign.headingLarge.copyWith(
            color: AppDesign.primaryText,
          ),
        ),
        const SizedBox(height: AppDesign.spacing8),
        Text(
          '새로운 여행을 시작하기 위해\n계정을 만들어주세요',
          style: AppDesign.bodyLarge.copyWith(
            color: AppDesign.secondaryText,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildSignupForm(BuildContext context, SignupViewModel viewModel) {
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
          _buildTextField(
            controller: _emailController,
            focusNode: _emailFocusNode,
            label: '이메일 주소',
            hint: 'example@email.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_passwordFocusNode);
            },
          ),

          const SizedBox(height: AppDesign.spacing24),

          // 비밀번호 입력 필드
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocusNode,
            label: '비밀번호',
            hint: '8자 이상 입력해주세요',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_confirmPasswordFocusNode);
            },
          ),

          const SizedBox(height: AppDesign.spacing24),

          // 비밀번호 확인 입력 필드
          _buildTextField(
            controller: _confirmPasswordController,
            focusNode: _confirmPasswordFocusNode,
            label: '비밀번호 확인',
            hint: '비밀번호를 다시 입력해주세요',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: AppDesign.spacing32),

          // 회원가입 버튼
          _buildSignupButton(context, viewModel),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData prefixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    Function(String)? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
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
              color: focusNode.hasFocus
                  ? AppDesign.travelBlue
                  : AppDesign.borderColor,
              width: focusNode.hasFocus ? 2 : 1,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onSubmitted: onSubmitted,
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.primaryText,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: AppDesign.bodyMedium.copyWith(
                color: AppDesign.subtleText,
              ),
              prefixIcon: Container(
                margin: const EdgeInsets.all(AppDesign.spacing12),
                decoration: BoxDecoration(
                  color: AppDesign.travelGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesign.spacing8),
                ),
                child: Icon(
                  prefixIcon,
                  color: AppDesign.travelGreen,
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

  Widget _buildSignupButton(BuildContext context, SignupViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppDesign.greenGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: AppDesign.travelGreen.withValues(alpha: 0.15),
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
                String password = _passwordController.text.trim();
                String confirmPassword = _confirmPasswordController.text.trim();

                String? errorMessage =
                    await viewModel.signUp(email, password, confirmPassword);

                if (errorMessage == null) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_outline,
                            color: AppDesign.whiteText,
                            size: 20,
                          ),
                          const SizedBox(width: AppDesign.spacing8),
                          Expanded(
                            child: Text(
                              '회원가입 성공! 로그인 페이지로 이동합니다.',
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
                  Navigator.pushReplacementNamed(context, '/login');
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
                  const Icon(Icons.person_add_outlined, size: 20),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    '회원가입',
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
}
