import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/login_option_viewmodel.dart';
import '../design/app_design.dart'; // 디자인 시스템 import

class EmailLoginPage extends StatefulWidget {
  const EmailLoginPage({super.key});

  @override
  State<EmailLoginPage> createState() => _EmailLoginPageState();
}

class _EmailLoginPageState extends State<EmailLoginPage> {
  late final LoginViewModel _viewModel;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  final FocusNode _emailFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  bool _emailEdited = false;
  bool _passwordEdited = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
    _viewModel = LoginViewModel();
    _emailController.addListener(() {
      _emailEdited = true;
      _viewModel.setEmail(_emailController.text);
    });
    _passwordController.addListener(
      () {
        _passwordEdited = true;
        _viewModel.setPassword(_passwordController.text);
      },
    );
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    await _viewModel.loadUserPreferences();
    if (!mounted) return;
    if (_emailEdited) {
      _viewModel.setEmail(_emailController.text);
    } else {
      _emailController.text = _viewModel.email;
    }
    if (_passwordEdited) {
      _viewModel.setPassword(_passwordController.text);
    } else {
      _passwordController.text = _viewModel.password;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocusNode.dispose();
    _passwordFocusNode.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<LoginViewModel>(
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

                            // 로그인 폼 카드
                            _buildLoginForm(context, viewModel),
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
            '이메일 로그인',
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
          '안녕하세요! 👋',
          style: AppDesign.headingLarge.copyWith(
            color: AppDesign.primaryText,
          ),
        ),
        const SizedBox(height: AppDesign.spacing8),
        Text(
          '이메일과 비밀번호로 로그인해주세요',
          style: AppDesign.bodyLarge.copyWith(
            color: AppDesign.secondaryText,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(BuildContext context, LoginViewModel viewModel) {
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
            label: '이메일',
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
            hint: '비밀번호를 입력해주세요',
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: true,
            textInputAction: TextInputAction.done,
          ),

          const SizedBox(height: AppDesign.spacing20),

          // Remember Me 체크박스
          _buildRememberMeCheckbox(viewModel),

          const SizedBox(height: AppDesign.spacing32),

          // 로그인 버튼
          _buildLoginButton(context, viewModel),
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
                  color: AppDesign.travelBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppDesign.spacing8),
                ),
                child: Icon(
                  prefixIcon,
                  color: AppDesign.travelBlue,
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

  Widget _buildRememberMeCheckbox(LoginViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing4),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.1,
            child: Checkbox(
              value: viewModel.rememberMe,
              onChanged: (v) => viewModel.setRememberMe(v ?? false),
              activeColor: AppDesign.travelBlue,
              checkColor: AppDesign.whiteText,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: AppDesign.spacing8),
          Text(
            '로그인 정보 기억하기',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context, LoginViewModel viewModel) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppDesign.primaryGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        boxShadow: AppDesign.glowShadow,
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
                String? error = await viewModel.login();
                if (error == null) {
                  if (!mounted) return;
                  if (!context.mounted) return;
                  Navigator.pushReplacementNamed(context, '/home');
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
                              error,
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
                  const Icon(Icons.login, size: 20),
                  const SizedBox(width: AppDesign.spacing8),
                  Text(
                    '로그인',
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
