import 'package:flutter/material.dart';
import '../../viewmodels/onboarding/onboarding_viewmodel.dart';
import '../../widgets/onboarding/intro_preview.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key, required this.onFinished});
  final VoidCallback onFinished;
  @override
  State<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final _vm = OnboardingViewModel();
  final _pages = PageController();
  static const _titles = [
    '발견한 장소를\n나만의 여행으로',
    '후기 속 장소를\n링크 하나로 모아요',
    '함께 준비하면\n여행이 더 즐거워요'
  ];
  static const _descriptions = [
    '마음에 드는 장소를 저장하고\n나만의 여행 리스트로 모아보세요.',
    '인스타그램·Threads·블로그의 글을\n공유하면 장소를 찾아드려요.',
    '리스트에 친구를 초대하고\n가고 싶은 장소를 함께 모아보세요.'
  ];
  Future<void> _finish() async {
    if (await _vm.finish() && mounted) widget.onFinished();
  }

  @override
  void dispose() {
    _vm.dispose();
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (!didPop && !_vm.saving) _finish();
            },
            child: Scaffold(
                backgroundColor: const Color(0xFFFAFAFA),
                body: SafeArea(
                    child: Column(children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 12, 0),
                      child: Row(children: [
                        const Expanded(
                            child: Text('TripNest',
                                style: TextStyle(
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1))),
                        TextButton(
                            onPressed: _vm.saving ? null : _finish,
                            style: TextButton.styleFrom(
                                foregroundColor: const Color(0xFF626266)),
                            child: const Text('건너뛰기')),
                      ])),
                  Expanded(
                      child: PageView.builder(
                          controller: _pages,
                          itemCount: 3,
                          onPageChanged: _vm.select,
                          itemBuilder: (context, index) =>
                              SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.fromLTRB(28, 8, 28, 12),
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                            width: double.infinity,
                                            height: (MediaQuery.sizeOf(context)
                                                        .height *
                                                    .48)
                                                .clamp(240.0, 470.0),
                                            child: IntroPreview(page: index)),
                                        const SizedBox(height: 16),
                                        Text(_titles[index],
                                            style: const TextStyle(
                                                fontSize: 33,
                                                height: 1.25,
                                                fontWeight: FontWeight.w800,
                                                color: Color(0xFF202023))),
                                        const SizedBox(height: 16),
                                        Text(_descriptions[index],
                                            style: const TextStyle(
                                                fontSize: 17,
                                                height: 1.6,
                                                color: Color(0xFF626266))),
                                      ])))),
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                      child: Column(children: [
                        Semantics(
                            label: '소개 ${_vm.page + 1} / 3',
                            child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(
                                    3,
                                    (index) => Container(
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        width: index == _vm.page ? 30 : 9,
                                        height: 9,
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: index == _vm.page
                                                ? const Color(0xFF222222)
                                                : const Color(0xFFD8D8DC)))))),
                        if (_vm.error != null)
                          Padding(
                              padding: const EdgeInsets.only(top: 12),
                              child: Text(_vm.error!,
                                  style: const TextStyle(color: Colors.red))),
                        const SizedBox(height: 22),
                        SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                                style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF222222),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(0, 56),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16))),
                                onPressed: _vm.saving
                                    ? null
                                    : () {
                                        if (_vm.page == 2) {
                                          _finish();
                                        } else if (MediaQuery
                                            .disableAnimationsOf(context)) {
                                          _pages.jumpToPage(_vm.page + 1);
                                        } else {
                                          _pages.nextPage(
                                              duration: const Duration(
                                                  milliseconds: 240),
                                              curve: Curves.easeOut);
                                        }
                                      },
                                child: Text(_vm.saving
                                    ? '저장 중…'
                                    : _vm.page == 2
                                        ? '여행 시작하기'
                                        : '다음'))),
                      ])),
                ])))),
      );
}
