import '../widgets/app_overlays.dart';
import 'package:flutter/material.dart';
import '../design/app_design.dart';

class TermsAgreementPage extends StatefulWidget {
  final String userId;
  const TermsAgreementPage({super.key, required this.userId});

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  bool _allChecked = false;
  bool _essentialChecked = false;
  bool _optionalChecked = false;

  void _updateAllChecked() {
    _allChecked = _essentialChecked && _optionalChecked;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      body: Container(
        decoration: const BoxDecoration(gradient: AppDesign.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              _buildProgressHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppDesign.spacing24),
                  child: Column(
                    children: [
                      const SizedBox(height: AppDesign.spacing40),
                      _buildHeader(),
                      const SizedBox(height: AppDesign.spacing48),
                      _buildTermsCard(),
                      const SizedBox(height: AppDesign.spacing48),
                      _buildNextButton(),
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
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text('약관 동의',
            style: AppDesign.headingLarge.copyWith(
              color: AppDesign.primaryText,
              fontWeight: FontWeight.w800,
            )),
        const SizedBox(height: AppDesign.spacing16),
        Text(
          '서비스 이용을 위해\n필수 약관에 동의해주세요.',
          style: AppDesign.bodyLarge.copyWith(
            color: AppDesign.secondaryText,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildTermsCard() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusXL),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        children: [
          _buildCheckboxTile('전체 동의하기', _allChecked, (val) {
            setState(() {
              _allChecked = val!;
              _essentialChecked = val;
              _optionalChecked = val;
            });
          }, isBold: true),
          const Divider(height: 32),
          _buildCheckboxTile('개인정보 수집 및 이용', _essentialChecked, (val) {
            setState(() {
              _essentialChecked = val!;
              _updateAllChecked();
            });
          },
              onViewPressed: () => _showTermsDialog(
                  context, '개인정보 수집 및 이용', '여기에 개인정보 처리방침 내용을 입력하세요.')),
          _buildCheckboxTile('위치기반서비스 이용약관', _optionalChecked, (val) {
            setState(() {
              _optionalChecked = val!;
              _updateAllChecked();
            });
          },
              onViewPressed: () => _showTermsDialog(
                  context, '위치기반서비스 이용약관', '여기에 위치기반서비스 약관 내용을 입력하세요.')),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile(String title, bool value, Function(bool?) onChanged,
      {bool isBold = false, VoidCallback? onViewPressed}) {
    return Theme(
      data: ThemeData(
        checkboxTheme: CheckboxThemeData(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        contentPadding: EdgeInsets.zero,
        dense: true,
        title: Text(
          title,
          style: AppDesign.bodyMedium.copyWith(
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? AppDesign.primaryText : AppDesign.secondaryText,
          ),
        ),
        secondary: onViewPressed != null
            ? InkWell(
                onTap: onViewPressed,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text('보기',
                      style: AppDesign.bodySmall.copyWith(
                        color: AppDesign.travelPurple,
                        decoration: TextDecoration.underline,
                      )),
                ),
              )
            : null,
        controlAffinity: ListTileControlAffinity.leading,
        activeColor: AppDesign.travelPurple,
      ),
    );
  }

  Widget _buildNextButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _essentialChecked
              ? AppDesign.travelPurple
              : AppDesign.borderColor,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium)),
        ),
        onPressed: _essentialChecked
            ? () => Navigator.pushReplacementNamed(context, '/nickname_setup',
                arguments: widget.userId)
            : null,
        child: const Text('다음',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
              Text('약관 동의',
                  style: AppDesign.bodyMedium
                      .copyWith(color: AppDesign.secondaryText)),
              Text('1/2',
                  style: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.travelBlue,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: 0.5, // 50% 진행 표시
            backgroundColor: AppDesign.borderColor,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context, String title, String content) {
    showAppSheet<void>(
        context: context,
        builder: (sheet) => AppSheet(
              title: title,
              footer: FilledButton(
                  onPressed: () => Navigator.pop(sheet),
                  child: const Text('확인')),
              children: [
                Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(content,
                        style: AppDesign.bodyMedium.copyWith(height: 1.7)))
              ],
            ));
  }
}
