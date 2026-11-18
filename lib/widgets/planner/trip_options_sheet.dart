import 'package:flutter/material.dart';

import '../../design/app_design.dart';
import '../../services/ai/planner_prompts.dart';

enum TripOptionsMode { nearby, stay, companion }

class TripOptionsSheet extends StatefulWidget {
  const TripOptionsSheet({super.key, required this.mode, required this.locate});
  final TripOptionsMode mode;
  final Future<String?> Function() locate;

  @override
  State<TripOptionsSheet> createState() => _TripOptionsSheetState();
}

class _TripOptionsSheetState extends State<TripOptionsSheet> {
  final _region = TextEditingController();
  final _selected = <String>{};
  final _extras = <String>{};
  String _space = '머물 숙소';
  String _companion = '';
  String _duration = '반나절';
  String _radius = '3km';
  String? _location;
  bool _locating = false;
  bool _locationFailed = false;
  bool _useLocation = false;

  bool get _nearby => widget.mode == TripOptionsMode.nearby;
  bool get _stay => widget.mode == TripOptionsMode.stay;
  bool get _valid =>
      !_locating &&
      (_useLocation ? _location != null : _region.text.trim().isNotEmpty) &&
      (_nearby || _stay ? _selected.isNotEmpty : _companion.isNotEmpty);

  String get _title => _nearby
      ? '주변에서 어디를 찾을까요?'
      : _stay
          ? '어떤 공간을 찾고 있나요?'
          : '누구와 함께 떠나세요?';
  String get _button => _nearby
      ? '주변 장소 추천받기'
      : _stay
          ? '원하는 공간 추천받기'
          : '함께할 여행 추천받기';
  String get _summary => [
        if (_nearby || _stay) ..._selected,
        if (_stay) _space,
        if (!_nearby && !_stay && _companion.isNotEmpty) _companion,
        if (_useLocation && _location != null) '현재 위치',
        if (!_useLocation && _region.text.trim().isNotEmpty)
          _region.text.trim(),
        if (_nearby) '반경 $_radius',
        if (!_nearby && !_stay) _duration,
        ..._extras,
      ].join(' · ');

  @override
  void dispose() {
    _region.dispose();
    super.dispose();
  }

  Future<void> _locate() async {
    setState(() {
      _useLocation = true;
      _locating = true;
      _locationFailed = false;
    });
    String? location;
    try {
      location = await widget.locate();
    } catch (_) {
      location = null;
    }
    if (!mounted) return;
    setState(() {
      _locating = false;
      _location = location;
      _locationFailed = location == null;
      if (location == null) _useLocation = false;
    });
  }

  void _submit() {
    if (!_valid) return;
    final region = _useLocation ? _location! : _region.text.trim();
    final String request;
    if (_nearby) {
      request = PlannerPrompts.nearby(region, _selected, _radius);
    } else if (_stay) {
      request = PlannerPrompts.stay(region, _space, _selected, _extras);
    } else {
      request =
          PlannerPrompts.companion(region, _companion, _duration, _extras);
    }
    Navigator.of(context).pop(request);
  }

  Widget _choices(String label, List<String> values,
          bool Function(String) selected, void Function(String) toggle,
          {bool multiple = false}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: AppDesign.spacing20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$label · ${multiple ? '복수 선택' : '하나 선택'}',
              style: AppDesign.bodyMedium),
          const SizedBox(height: AppDesign.spacing8),
          Wrap(
            spacing: AppDesign.spacing8,
            runSpacing: AppDesign.spacing8,
            children: values
                .map((value) => FilterChip(
                      label: Text(value),
                      selected: selected(value),
                      onSelected: (_) => setState(() => toggle(value)),
                      showCheckmark: true,
                      selectedColor: AppDesign.secondaryBg,
                      backgroundColor: AppDesign.cardBg,
                      checkmarkColor: AppDesign.primary,
                      side: BorderSide(
                          color: selected(value)
                              ? AppDesign.primary
                              : AppDesign.borderColor),
                      labelStyle: AppDesign.bodyMedium,
                    ))
                .toList(),
          ),
        ]),
      );

  void _toggle(Set<String> values, String value) {
    if (!values.add(value)) values.remove(value);
  }

  @override
  Widget build(BuildContext context) => SafeArea(
        top: false,
        child: Padding(
          padding:
              EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(_title, style: AppDesign.headingMedium)),
                    IconButton(
                        tooltip: '닫기',
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ]),
                  const Text('원하는 조건을 고르면 맞춤 추천을 받을 수 있어요.',
                      style: AppDesign.bodySmall),
                  const SizedBox(height: AppDesign.spacing24),
                  if (_nearby) ...[
                    _choices('장소 종류', ['산책·공원', '볼거리·문화', '맛집', '카페'],
                        _selected.contains, (v) => _toggle(_selected, v),
                        multiple: true),
                    const Text('검색 기준', style: AppDesign.bodyMedium),
                    const SizedBox(height: AppDesign.spacing8),
                    Wrap(spacing: AppDesign.spacing8, children: [
                      OutlinedButton.icon(
                          onPressed: _locating ? null : _locate,
                          icon: const Icon(Icons.my_location),
                          label: Text(_locating
                              ? '위치 확인 중…'
                              : _useLocation
                                  ? '현재 위치 선택됨'
                                  : '현재 위치 사용')),
                      TextButton(
                          onPressed: _locating
                              ? null
                              : () => setState(() => _useLocation = false),
                          child: const Text('지역 직접 입력')),
                    ]),
                    if (_locationFailed)
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 8),
                        child: Text(
                            '위치를 확인하지 못했어요. 지역을 직접 입력하거나 위치 설정을 확인 후 다시 시도해주세요.',
                            style: AppDesign.bodySmall),
                      ),
                    const SizedBox(height: AppDesign.spacing12),
                  ],
                  if (_stay) ...[
                    _choices('공간 구분', ['머물 숙소', '잠깐 들를 공간'], (v) => _space == v,
                        (v) {
                      _space = v;
                      _extras.clear();
                    }),
                    _choices(
                        '원하는 분위기',
                        ['조용한', '자연 속', '감성적인', '전망 좋은', '사진 찍기 좋은'],
                        _selected.contains,
                        (v) => _toggle(_selected, v),
                        multiple: true),
                  ],
                  if (!_nearby && !_stay)
                    _choices('동행 유형', ['친구', '연인', '가족', '모임'],
                        (v) => _companion == v, (v) => _companion = v),
                  if (!_useLocation)
                    TextField(
                      controller: _region,
                      onChanged: (_) => setState(() {}),
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => FocusScope.of(context).unfocus(),
                      decoration: const InputDecoration(
                          labelText: '여행 지역',
                          hintText: '예: 강릉, 서울 성수동',
                          prefixIcon: Icon(Icons.location_on_outlined)),
                    ),
                  const SizedBox(height: AppDesign.spacing20),
                  if (_nearby)
                    _choices('검색 반경', ['1km', '3km', '5km'],
                        (v) => _radius == v, (v) => _radius = v),
                  if (!_nearby && !_stay)
                    _choices('여행 기간', ['반나절', '당일', '1박 2일', '2박 3일'],
                        (v) => _duration == v, (v) => _duration = v),
                  if (!_nearby)
                    ExpansionTile(
                      title:
                          const Text('추가 조건 (선택)', style: AppDesign.bodyMedium),
                      tilePadding: EdgeInsets.zero,
                      children: [
                        _choices(
                            _stay ? '선호 유형' : '동행 배려 조건',
                            _stay
                                ? (_space == '머물 숙소'
                                    ? ['호텔', '펜션', '독채', '한옥']
                                    : ['카페', '전시', '서점', '복합문화공간'])
                                : ['아이와 함께', '어르신과 함께', '여러 명이 함께', '걷기 적게'],
                            _extras.contains,
                            (v) => _toggle(_extras, v),
                            multiple: true),
                      ],
                    ),
                  if (_summary.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppDesign.spacing16),
                      child: Text(_summary, style: AppDesign.bodySmall),
                    ),
                  SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                          onPressed: _valid ? _submit : null,
                          child: Text(_button))),
                ]),
          ),
        ),
      );
}
