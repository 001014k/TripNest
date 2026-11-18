import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../../services/ai/planner_prompts.dart';

/// 선택을 완료했을 때만 추천 요청을 반환합니다.
class ThemeTripSheet extends StatefulWidget {
  const ThemeTripSheet({super.key});

  @override
  State<ThemeTripSheet> createState() => _ThemeTripSheetState();
}

class _ThemeTripSheetState extends State<ThemeTripSheet> {
  final _regionController = TextEditingController();
  final _selected = <String>{};

  static const _themes = [
    (
      name: '힐링',
      description: '자연 속 산책과 여유로운 휴식',
      icon: Icons.spa_outlined,
    ),
    (
      name: '맛집',
      description: '지역 음식과 현지 맛집 탐방',
      icon: Icons.restaurant_outlined,
    ),
    (
      name: '카페',
      description: '분위기 좋은 카페와 디저트',
      icon: Icons.local_cafe_outlined,
    ),
  ];

  bool get _canSubmit =>
      _selected.isNotEmpty && _regionController.text.trim().isNotEmpty;

  @override
  void dispose() {
    _regionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    final themes = _themes.where((theme) => _selected.contains(theme.name));
    final request = PlannerPrompts.theme(
        _regionController.text, themes.map((theme) => theme.name));
    Navigator.of(context).pop(request);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child:
                        Text('어떤 여행을 하고 싶으세요?', style: AppDesign.headingMedium),
                  ),
                  IconButton(
                    tooltip: '닫기',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text('원하는 테마를 함께 골라주세요. 여러 개 선택할 수 있어요.',
                  style: AppDesign.bodySmall),
              const SizedBox(height: AppDesign.spacing24),
              for (final theme in _themes)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppDesign.spacing12),
                  child: Semantics(
                    selected: _selected.contains(theme.name),
                    child: Material(
                      color: _selected.contains(theme.name)
                          ? AppDesign.secondaryBg
                          : AppDesign.cardBg,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AppDesign.radiusMedium),
                        side: BorderSide(
                          color: _selected.contains(theme.name)
                              ? AppDesign.primary
                              : AppDesign.borderColor,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => setState(() {
                          if (!_selected.add(theme.name)) {
                            _selected.remove(theme.name);
                          }
                        }),
                        child: Padding(
                          padding: const EdgeInsets.all(AppDesign.spacing16),
                          child: Row(
                            children: [
                              Icon(theme.icon, color: AppDesign.primary),
                              const SizedBox(width: AppDesign.spacing16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(theme.name,
                                        style: AppDesign.headingSmall),
                                    const SizedBox(height: AppDesign.spacing4),
                                    Text(theme.description,
                                        style: AppDesign.bodySmall),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppDesign.spacing8),
                              Icon(
                                _selected.contains(theme.name)
                                    ? Icons.check_circle
                                    : Icons.radio_button_unchecked,
                                color: _selected.contains(theme.name)
                                    ? AppDesign.primary
                                    : AppDesign.borderColor,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppDesign.spacing12),
              TextField(
                controller: _regionController,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _submit(),
                decoration: const InputDecoration(
                  labelText: '여행 지역',
                  hintText: '예: 강릉, 서울 성수동',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
              ),
              const SizedBox(height: AppDesign.spacing16),
              const Text('기본 반나절 코스로 추천해요. 세부 조건은 채팅에서 조정할 수 있어요.',
                  style: AppDesign.bodySmall),
              const SizedBox(height: AppDesign.spacing16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _canSubmit ? _submit : null,
                  child: const Text('선택한 테마로 추천받기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
