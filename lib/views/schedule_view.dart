import '../design/map_style.dart';
import '../services/marker_icon_service.dart';
import '../widgets/address_photo_preview.dart';
import '../models/list_schedule_draft.dart';
import '../models/marker_model.dart';
import '../navigation/app_tab_shell.dart';
import '../navigation/app_page_route.dart';
import '../widgets/app_overlays.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/marker_service.dart';
import '../viewmodels/friend_management_viewmodel.dart';
import '../widgets/reference_design.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../design/app_design.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../widgets/tripnest_navigation.dart';

class ScheduleView extends StatefulWidget {
  const ScheduleView({super.key});
  @override
  State<ScheduleView> createState() => _ScheduleViewState();
}

class _ScheduleViewState extends State<ScheduleView> {
  final _service = ScheduleService();
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  late Future<List<ScheduleModel>> _items;
  DateTime _month = DateTime.now();

  @override
  void initState() {
    super.initState();
    _reload();
    ScheduleService.changes.addListener(_onSchedulesChanged);
  }

  void _onSchedulesChanged() {
    if (mounted) setState(_reload);
  }

  @override
  void dispose() {
    ScheduleService.changes.removeListener(_onSchedulesChanged);
    super.dispose();
  }

  bool _tabWasActive = true;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = AppTabVisibility.maybeOf(context)?.active ?? true;
    if (active && !_tabWasActive) _reload();
    _tabWasActive = active;
  }

  void _reload() {
    _items = _service.fetchByDateRange(
        DateTime(_month.year, _month.month),
        DateTime(_month.year, _month.month + 1)
            .subtract(const Duration(microseconds: 1)));
  }

  Future<void> _edit([ScheduleModel? item]) async {
    await Navigator.push<bool>(
        context,
        AppPageRoute(
          motion: AppMotion.editor,
          builder: (_) => ScheduleEditView(date: _date, schedule: item),
        ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.primaryBg,
        bottomNavigationBar:
            const TripNestNavigation(currentRoute: '/schedule'),
        floatingActionButton: FloatingActionButton(
            onPressed: () => _edit(),
            tooltip: '일정 추가',
            backgroundColor: AppDesign.primary,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            child: const Icon(Icons.add, size: 32)),
        body: SafeArea(
            child: FutureBuilder<List<ScheduleModel>>(
                future: _items,
                builder: (context, snapshot) {
                  final all = snapshot.data ?? [];
                  final items = all
                      .where((item) =>
                          DateUtils.isSameDay(item.startTime.toLocal(), _date))
                      .toList()
                    ..sort((a, b) => a.startTime.compareTo(b.startTime));
                  return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 85),
                      children: [
                        const TripNestHeader(),
                        const SizedBox(height: 20),
                        const Text('일정',
                            style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8)),
                        const SizedBox(height: 7),
                        const Text('여행의 소중한 순간들을 일정으로 계획해보세요.',
                            style: AppDesign.bodySmall),
                        const SizedBox(height: 18),
                        ReferenceCalendar(
                            month: _month,
                            selected: _date,
                            eventDays: all
                                .map((item) => item.startTime.toLocal().day)
                                .toSet(),
                            onSelected: (date) => setState(() {
                                  _date = date;
                                  if (date.month != _month.month ||
                                      date.year != _month.year) {
                                    _month = date;
                                    _reload();
                                  }
                                }),
                            onMonthChanged: (date) => setState(() {
                                  _month = date;
                                  _date = date;
                                  _reload();
                                })),
                        const SizedBox(height: 22),
                        Row(children: [
                          const Expanded(
                              child: Text('오늘 / 예정된 일정',
                                  style: AppDesign.headingSmall)),
                          Text(
                              '${_date.month}월 ${_date.day}일 (${'월화수목금토일'[_date.weekday - 1]})',
                              style: AppDesign.caption)
                        ]),
                        const SizedBox(height: 12),
                        if (snapshot.connectionState != ConnectionState.done)
                          const LinearProgressIndicator()
                        else if (snapshot.hasError)
                          TextButton(
                              onPressed: () => setState(_reload),
                              child: const Text('일정을 불러오지 못했어요. 다시 시도'))
                        else if (items.isEmpty)
                          const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text('이날의 첫 일정을 추가해보세요.',
                                  textAlign: TextAlign.center,
                                  style: AppDesign.bodySmall))
                        else
                          for (final item in items)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: ReferenceCard(
                                  child: InkWell(
                                      onTap: () => _edit(item),
                                      child: Row(children: [
                                        Column(children: [
                                          Text(_time(item.startTime.toLocal()),
                                              style: const TextStyle(
                                                  fontSize: 17,
                                                  fontWeight: FontWeight.w700)),
                                          Container(
                                              width: 1,
                                              height: 8,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                      vertical: 4),
                                              color: AppDesign.borderColor),
                                          Text(_time(item.endTime.toLocal()),
                                              style: AppDesign.caption)
                                        ]),
                                        const SizedBox(width: 12),
                                        ReferencePhoto(
                                            title: item.title,
                                            width: 62,
                                            height: 68),
                                        const SizedBox(width: 12),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text(item.title,
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      fontWeight:
                                                          FontWeight.w700)),
                                              const SizedBox(height: 6),
                                              Text(
                                                  item.placeId == null
                                                      ? '장소 미지정'
                                                      : '저장된 장소',
                                                  style: AppDesign.caption),
                                              const SizedBox(height: 6),
                                              ReferencePeople(
                                                  count: item.collaboratorIds
                                                          ?.length ??
                                                      0),
                                            ])),
                                        SizedBox(
                                            width: 22,
                                            child: IconButton(
                                                padding: EdgeInsets.zero,
                                                tooltip: '일정 편집',
                                                onPressed: () => _edit(item),
                                                icon: const Icon(
                                                    Icons.more_horiz,
                                                    color: AppDesign
                                                        .secondaryText))),
                                      ])),
                                )),
                      ]);
                })),
      );
}

String _time(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

class ScheduleEditView extends StatefulWidget {
  final DateTime date;
  final ScheduleModel? schedule;
  final List<MarkerModel> initialPlaces;
  final String? initialTitle;
  const ScheduleEditView(
      {super.key,
      required this.date,
      this.schedule,
      this.initialPlaces = const [],
      this.initialTitle});
  @override
  State<ScheduleEditView> createState() => _ScheduleEditViewState();
}

class _ScheduleEditViewState extends State<ScheduleEditView> {
  final _form = GlobalKey<FormState>();
  final _service = ScheduleService();
  late final TextEditingController _title;
  late DateTime _start;
  late DateTime _end;
  bool _saving = false;
  String? _placeId;
  String _placeLabel = '장소 미지정';
  String _placeAddress = '';
  BitmapDescriptor? _placeIcon;
  int _placeIconRequest = 0;
  double? _latitude;
  double? _longitude;
  late List<String> _participants;

  @override
  void initState() {
    super.initState();
    _placeId = widget.schedule?.placeId;
    _latitude = widget.schedule?.latitude;
    _longitude = widget.schedule?.longitude;
    _participants = [...?widget.schedule?.collaboratorIds];
    if (_placeId != null) {
      _placeLabel = '장소명을 불러오는 중…';
      _loadPlaceLabel(_placeId!);
    }
    _title = TextEditingController(
        text: widget.schedule?.title ?? widget.initialTitle ?? '');
    _start = widget.schedule?.startTime.toLocal() ??
        DateTime(widget.date.year, widget.date.month, widget.date.day, 11);
    _end = widget.schedule?.endTime.toLocal() ??
        _start.add(Duration(
            hours: widget.initialPlaces.isEmpty
                ? 1
                : widget.initialPlaces.length));
  }

  Future<void> _loadPlaceLabel(String placeId) async {
    try {
      final place = await MarkerService().loadMarkerDetail(placeId);
      if (!mounted || _placeId != placeId) return;
      final title = place?['title']?.toString().trim();
      setState(() {
        _placeLabel = title == null || title.isEmpty ? '연결된 장소 정보 없음' : title;
        _placeAddress = place?['address']?.toString().trim() ?? '';
        _latitude = (place?['lat'] as num?)?.toDouble() ?? _latitude;
        _longitude = (place?['lng'] as num?)?.toDouble() ?? _longitude;
      });
      await _loadPlaceIcon(place?['keyword']?.toString() ?? '');
    } catch (_) {
      if (!mounted || _placeId != placeId) return;
      setState(() => _placeLabel = '장소명을 불러오지 못했어요');
    }
  }

  Future<void> _loadPlaceIcon(String keyword) async {
    final request = ++_placeIconRequest;
    final placeId = _placeId;
    if (mounted) setState(() => _placeIcon = null);
    final icon = await MarkerIconService().createKeywordMarker(keyword);
    if (!mounted || request != _placeIconRequest || placeId != _placeId) return;
    setState(() => _placeIcon = icon);
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
        context: context,
        initialDate: _start,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (date == null || !mounted) return;
    setState(() {
      final duration = _end.difference(_start);
      _start =
          DateTime(date.year, date.month, date.day, _start.hour, _start.minute);
      _end = _start.add(duration);
    });
  }

  Future<void> _pickTime(bool start) async {
    final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(start ? _start : _end));
    if (time == null || !mounted) return;
    setState(() {
      final base = start ? _start : _end;
      final value =
          DateTime(base.year, base.month, base.day, time.hour, time.minute);
      if (start) {
        final duration = _end.difference(_start);
        _start = value;
        _end = value.add(duration);
      } else {
        _end = value;
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!_form.currentState!.validate()) return;
    if (!_end.isAfter(_start)) {
      _error('종료 시간은 시작 시간보다 늦어야 합니다.');
      return;
    }
    if (widget.initialPlaces.isNotEmpty &&
        _end.difference(_start).inMinutes < widget.initialPlaces.length) {
      _error('장소마다 최소 1분 이상의 시간을 지정해주세요.');
      return;
    }
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) {
      _error('로그인 후 일정을 저장해주세요.');
      return;
    }
    setState(() => _saving = true);
    final old = widget.schedule;
    try {
      if (widget.initialPlaces.isNotEmpty) {
        await _service.addAll(buildListSchedules(
            places: widget.initialPlaces,
            userId: userId,
            title: _title.text,
            start: _start,
            end: _end,
            participants: _participants));
      } else {
        await _service.addOrUpdate(ScheduleModel(
            id: old?.id ?? const Uuid().v4(),
            userId: old?.userId ?? userId,
            title: _title.text.trim(),
            startTime: _start,
            endTime: _end,
            colorValue: old?.colorValue ?? 0xFF222222,
            placeId: _placeId,
            latitude: _latitude,
            longitude: _longitude,
            collaboratorIds: _participants));
      }
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _error('저장하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _error(String text) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => const AppConfirmDialog(
          title: '일정을 삭제할까요?',
          message: '삭제한 일정은 되돌릴 수 없습니다.',
          confirmLabel: '삭제',
          destructive: true,
          icon: Icons.event_busy_outlined),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _saving = true);
    try {
      await _service.delete(widget.schedule!.id);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      _error('삭제하지 못했어요. 다시 시도해주세요.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickPlace() async {
    try {
      final places = await MarkerService().getRecentMarkers(limit: 100);
      if (!mounted) return;
      final selected = await showAppSheet<Map<String, dynamic>>(
        context: context,
        builder: (sheet) => AppSheet(
          title: '저장한 장소 선택',
          subtitle: '이 일정에 연결할 장소를 선택해주세요.',
          children: [
            if (places.isEmpty)
              const Padding(
                  padding: EdgeInsets.all(20),
                  child:
                      Text('먼저 지도에 장소를 저장해주세요.', style: AppDesign.bodyMedium)),
            for (final place in places)
              AppSheetOption(
                title: place['title']?.toString() ?? '장소',
                subtitle: place['address']?.toString(),
                icon: Icons.place_outlined,
                selected: place['id']?.toString() == _placeId,
                onTap: () => Navigator.pop(sheet, place),
              ),
          ],
        ),
      );
      if (selected != null && mounted) {
        setState(() {
          _placeId = selected['id']?.toString();
          _placeLabel = selected['title']?.toString() ?? '장소';
          _placeAddress = selected['address']?.toString().trim() ?? '';
          _latitude = (selected['lat'] as num?)?.toDouble();
          _longitude = (selected['lng'] as num?)?.toDouble();
        });
        await _loadPlaceIcon(selected['keyword']?.toString() ?? '');
      }
    } catch (_) {
      _error('장소를 불러오지 못했어요. 다시 시도해주세요.');
    }
  }

  Future<void> _pickParticipants() async {
    final vm = FriendManagementViewModel();
    try {
      final friends = await vm.getFriendsList();
      if (!mounted) return;
      final selected = {..._participants};
      final result = await showAppSheet<List<String>>(
        context: context,
        builder: (sheet) => StatefulBuilder(
            builder: (context, update) => AppSheet(
                  title: '참석자 선택',
                  subtitle: '함께 여행할 친구를 선택해주세요.',
                  footer: FilledButton(
                      onPressed: () => Navigator.pop(sheet, selected.toList()),
                      child: Text('선택 완료 · ${selected.length}명')),
                  children: [
                    if (friends.isEmpty)
                      const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('등록된 친구가 없어요.',
                              style: AppDesign.bodyMedium)),
                    for (final friend in friends)
                      AppSheetOption(
                        title: friend['nickname']?.toString() ?? '친구',
                        icon: Icons.person_outline,
                        selected: selected.contains(friend['id']),
                        onTap: () => update(() {
                          final id = friend['id'] as String;
                          selected.contains(id)
                              ? selected.remove(id)
                              : selected.add(id);
                        }),
                      ),
                  ],
                )),
      );
      if (result != null && mounted) setState(() => _participants = result);
    } catch (_) {
      _error('친구 목록을 불러오지 못했어요.');
    } finally {
      vm.dispose();
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: AppDesign.primaryBg,
        bottomNavigationBar: SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                        backgroundColor: AppDesign.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16))),
                    child: Text(_saving
                        ? '처리 중…'
                        : widget.initialPlaces.isEmpty
                            ? '저장'
                            : '${widget.initialPlaces.length}개 일정 추가')))),
        body: SafeArea(
            child: Form(
                key: _form,
                child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    children: [
                      TripNestHeader(
                          onBack: _saving ? null : () => Navigator.pop(context),
                          trailing: widget.schedule == null
                              ? const SizedBox(width: 48)
                              : IconButton(
                                  tooltip: '일정 삭제',
                                  onPressed: _saving ? null : _delete,
                                  icon: const Icon(Icons.delete_outline))),
                      const SizedBox(height: 20),
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              TextFormField(
                                  controller: _title,
                                  enabled: !_saving,
                                  style: const TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w800),
                                  decoration: const InputDecoration(
                                      hintText: '일정 제목',
                                      filled: false,
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                          ? '일정 제목을 입력해주세요.'
                                          : null),
                              const Text('일정 정보를 수정해보세요.',
                                  style: AppDesign.bodySmall),
                            ])),
                        const SizedBox(width: 12),
                        ReferencePhoto(
                            title: widget.initialPlaces.isNotEmpty
                                ? widget.initialPlaces.first.title
                                : _placeId != null
                                    ? _placeLabel
                                    : _title.text,
                            address: widget.initialPlaces.isNotEmpty
                                ? widget.initialPlaces.first.address
                                : _placeAddress,
                            width: 96,
                            height: 80),
                      ]),
                      const SizedBox(height: 18),
                      _field(
                          Icons.calendar_today_outlined,
                          '날짜',
                          '${_start.year}년 ${_start.month}월 ${_start.day}일',
                          _pickDate),
                      _field(Icons.access_time_rounded, '시작 시간', _time(_start),
                          () => _pickTime(true)),
                      _field(
                          Icons.access_time_rounded,
                          '종료 시간',
                          '${_end.month}월 ${_end.day}일 ${_time(_end)}',
                          () => _pickTime(false)),
                      if (widget.initialPlaces.isNotEmpty)
                        _listPlacesPreview()
                      else
                        ReferenceCard(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              InkWell(
                                onTap: _saving ? null : _pickPlace,
                                borderRadius: BorderRadius.circular(8),
                                child: ConstrainedBox(
                                  constraints:
                                      const BoxConstraints(minHeight: 48),
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(children: [
                                      const Icon(Icons.place_outlined,
                                          size: 26),
                                      const SizedBox(width: 12),
                                      Expanded(
                                          child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text('장소',
                                              style: AppDesign.caption),
                                          const SizedBox(height: 4),
                                          Text(_placeLabel,
                                              style: AppDesign.bodyMedium),
                                        ],
                                      )),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right),
                                    ]),
                                  ),
                                ),
                              ),
                              if (_latitude != null && _longitude != null)
                                ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: SizedBox(
                                        height: 110,
                                        child: GoogleMap(
                                            style: tripNestMapStyle,
                                            initialCameraPosition:
                                                CameraPosition(
                                                    target: LatLng(_latitude!,
                                                        _longitude!),
                                                    zoom: 14),
                                            key: ValueKey(
                                                '$_latitude,$_longitude'),
                                            zoomControlsEnabled: false,
                                            mapToolbarEnabled: false,
                                            myLocationButtonEnabled: false,
                                            myLocationEnabled: false,
                                            scrollGesturesEnabled: false,
                                            zoomGesturesEnabled: false,
                                            rotateGesturesEnabled: false,
                                            tiltGesturesEnabled: false,
                                            markers: {
                                              if (_placeIcon != null)
                                                Marker(
                                                    icon: _placeIcon!,
                                                    anchor:
                                                        const Offset(.5, .865),
                                                    markerId: const MarkerId(
                                                        'schedule-place'),
                                                    position: LatLng(_latitude!,
                                                        _longitude!))
                                            }))),
                              if (_placeId != null) ...[
                                const SizedBox(height: 8),
                                Container(
                                  decoration: BoxDecoration(
                                      border: Border.all(
                                          color: const Color(0xFFECEDEF)),
                                      borderRadius: BorderRadius.circular(10)),
                                  child: InkWell(
                                    onTap: _saving ? null : _pickPlace,
                                    borderRadius: BorderRadius.circular(10),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 13),
                                      child: Row(children: [
                                        const Icon(Icons.location_on_outlined,
                                            size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(
                                                _placeAddress.isEmpty
                                                    ? '주소 정보 없음'
                                                    : _placeAddress,
                                                style: const TextStyle(
                                                    fontSize: 13,
                                                    color:
                                                        AppDesign.secondaryText,
                                                    height: 1.4))),
                                        const SizedBox(width: 8),
                                        const Icon(Icons.chevron_right,
                                            size: 20,
                                            color: AppDesign.secondaryText),
                                      ]),
                                    ),
                                  ),
                                ),
                              ],
                            ])),
                      const SizedBox(height: 12),
                      _field(Icons.notes_rounded, '메모', '메모 없음', null),
                      _field(Icons.people_outline, '참석자',
                          '${_participants.length}명', _pickParticipants),
                    ]))),
      );
  Widget _listPlacesPreview() {
    final count = widget.initialPlaces.length;
    final minutes = _end.difference(_start).inMinutes;
    return ReferenceCard(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('리스트 장소 $count개', style: AppDesign.headingSmall),
        const SizedBox(height: 6),
        const Text('리스트 순서대로 방문할 장소예요.', style: AppDesign.bodySmall),
        const SizedBox(height: 18),
        for (var i = 0; i < count; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(height: 1, color: AppDesign.borderColor),
            ),
          _listPlacePreview(i, count, minutes),
        ],
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: AppDesign.secondaryBg,
              borderRadius: BorderRadius.circular(12)),
          child: const Text('시간은 균등 배정돼요. 이동 시간은 별도이며, 저장 후 각 일정을 수정할 수 있어요.',
              style: AppDesign.bodySmall),
        ),
      ]),
    );
  }

  Widget _listPlacePreview(int index, int count, int minutes) {
    final place = widget.initialPlaces[index];
    final start = _start.add(Duration(minutes: minutes * index ~/ count));
    final end = index == count - 1
        ? _end
        : _start.add(Duration(minutes: minutes * (index + 1) ~/ count));
    String label(DateTime value) => DateUtils.isSameDay(value, _start)
        ? _time(value)
        : '${value.month}/${value.day} ${_time(value)}';
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 60,
            height: 60,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AddressPhotoPreview(
                    key: ValueKey('schedule-preview-${place.id}'),
                    address: place.address,
                    title: place.title,
                    size: 60))),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${index + 1}번째 장소',
              style:
                  AppDesign.caption.copyWith(color: AppDesign.secondaryText)),
          const SizedBox(height: 4),
          Text(place.title,
              style: AppDesign.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700, color: AppDesign.primaryText)),
        ])),
      ]),
      const SizedBox(height: 10),
      Text(place.address.isEmpty ? '주소 정보 없음' : place.address,
          style: AppDesign.bodySmall.copyWith(color: AppDesign.secondaryText)),
      const SizedBox(height: 10),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
            color: AppDesign.secondaryBg,
            borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.schedule_rounded,
              size: 14, color: AppDesign.secondaryText),
          const SizedBox(width: 6),
          Flexible(
              child: Text(
                  minutes < count
                      ? '시간을 더 확보해주세요'
                      : '${label(start)}–${label(end)}',
                  style:
                      AppDesign.caption.copyWith(fontWeight: FontWeight.w600))),
        ]),
      ),
    ]);
  }

  Widget _field(
          IconData icon, String label, String value, VoidCallback? onTap) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: ReferenceCard(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 6),
            child: ListTile(
                enabled: !_saving,
                onTap: onTap,
                leading: Icon(icon, color: AppDesign.primaryText),
                title: Text(label, style: AppDesign.caption),
                subtitle: Text(value, style: AppDesign.bodyMedium),
                trailing:
                    onTap == null ? null : const Icon(Icons.chevron_right))),
      );
}
