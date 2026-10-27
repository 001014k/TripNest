import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/markers/markercreationscreen_viewmodel.dart';
import '../../widgets/places/address_photo_preview.dart';
import '../../widgets/places/place_keyword_icon.dart';
import '../../widgets/common/app_overlays.dart';
import '../../viewmodels/lists/list_viewmodel.dart';

class MarkerCreationScreen extends StatefulWidget {
  final LatLng initialLatLng;
  final String? initialTitle;
  final String? initialAddress;
  const MarkerCreationScreen(
      {required this.initialLatLng,
      this.initialTitle,
      this.initialAddress,
      super.key});
  @override
  State<MarkerCreationScreen> createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen> {
  late final TextEditingController _title;
  final _memo = TextEditingController();
  final _scroll = ScrollController();
  int _step = 0;
  String? _keyword;
  String? _listId;
  String _address = '주소 불러오는 중…';
  bool _loadingLists = true;
  bool _listError = false;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _title = TextEditingController(text: widget.initialTitle ?? '');
    _address = widget.initialAddress?.trim() ?? '';
    _loadAddress();
    _loadLists();
  }

  Future<void> _loadAddress() async {
    if (_address.isNotEmpty) return;
    final vm = context.read<MarkerCreationScreenViewModel>();
    final address = await vm.getAddressFromCoordinates(
        widget.initialLatLng.latitude, widget.initialLatLng.longitude);
    if (mounted) setState(() => _address = address);
  }

  Future<void> _loadLists() async {
    setState(() {
      _loadingLists = true;
      _listError = false;
    });
    try {
      await context.read<MarkerCreationScreenViewModel>().fetchUserLists();
    } catch (_) {
      if (mounted) setState(() => _listError = true);
    } finally {
      if (mounted) setState(() => _loadingLists = false);
    }
  }

  void _next() {
    if (_step == 0 && _title.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('장소 이름을 입력해주세요.')));
      return;
    }
    if (_step == 1 && _keyword == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('카테고리를 선택해주세요.')));
      return;
    }
    FocusScope.of(context).unfocus();
    if (_step < 2) {
      setState(() => _step++);
      _scroll.jumpTo(0);
    } else {
      Navigator.pop(context, <String, dynamic>{
        'title': _title.text.trim(),
        'snippet': _memo.text.trim(),
        'keyword': _keyword,
        'image': null,
        'listId': _listId,
        'address': _address,
      });
    }
  }

  Future<void> _createList() async {
    final name = await showDialog<String>(
        context: context,
        builder: (_) => const AppTextInputDialog(
            title: '새 리스트 만들기',
            hint: '리스트 이름',
            submitLabel: '만들기',
            icon: Icons.playlist_add_rounded));
    if (!mounted || name == null || name.trim().isEmpty) return;
    setState(() => _creating = true);
    try {
      final id = await context
          .read<MarkerCreationScreenViewModel>()
          .createList(name.trim());
      if (!mounted) return;
      setState(() => _listId = id);
      await _loadLists();
      if (mounted) await context.read<ListViewModel>().loadLists();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('리스트를 만들지 못했어요. 다시 시도해주세요.')));
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _memo.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MarkerCreationScreenViewModel>();
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFD),
      appBar: AppBar(
          backgroundColor: const Color(0xFFFCFCFD),
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: const Text('마커 추가하기',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          leading: IconButton(
              tooltip: '닫기',
              icon: const Icon(Icons.close, size: 22),
              onPressed: () => Navigator.pop(context))),
      bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
            child: FilledButton(
                onPressed: _creating ? null : _next,
                style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF191919),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(54),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18))),
                child: Text(_step == 2 ? '저장하기' : '다음',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600))),
          )),
      body: Column(children: [
        Padding(
            padding: const EdgeInsets.fromLTRB(32, 4, 32, 20),
            child: Row(
                children: List.generate(
                    3,
                    (index) => Expanded(
                            child: InkWell(
                          onTap: index < _step
                              ? () {
                                  setState(() => _step = index);
                                  _scroll.jumpTo(0);
                                }
                              : null,
                          child: Column(children: [
                            Row(children: [
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: index == 0
                                          ? Colors.transparent
                                          : index <= _step
                                              ? Colors.black
                                              : const Color(0xFFD7D8DC))),
                              Container(
                                  width: 18,
                                  height: 18,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: index <= _step
                                          ? Colors.black
                                          : const Color(0xFFC6C8CD)),
                                  child: index == _step
                                      ? const Icon(Icons.check,
                                          color: Colors.white, size: 12)
                                      : null),
                              Expanded(
                                  child: Container(
                                      height: 1,
                                      color: index == 2
                                          ? Colors.transparent
                                          : index < _step
                                              ? Colors.black
                                              : const Color(0xFFD7D8DC))),
                            ]),
                            const SizedBox(height: 9),
                            Text(['기본 정보', '카테고리', '저장하기'][index],
                                style: TextStyle(
                                    fontSize: 12,
                                    color: index == _step
                                        ? Colors.black
                                        : const Color(0xFF858892))),
                          ]),
                        ))))),
        Expanded(
            child: ListView(
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
                children: [
              if (_step == 0) ...[
                ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                        height: 190,
                        child: AddressPhotoPreview(
                            address: _address,
                            title: widget.initialTitle ?? _title.text,
                            size: 190))),
                const SizedBox(height: 22),
                _label('장소 이름'),
                TextField(
                    controller: _title,
                    textInputAction: TextInputAction.next,
                    decoration: _input('장소 이름을 입력해주세요.')),
                const SizedBox(height: 20),
                _label('설명 (선택)'),
                TextField(
                    controller: _memo,
                    minLines: 3,
                    maxLines: 5,
                    decoration: _input('이 장소에 대한 소개나 메모를 남겨주세요.')),
                const SizedBox(height: 20),
                _label('주소'),
                Container(
                    padding: const EdgeInsets.all(13),
                    decoration: _border,
                    child: Row(children: [
                      const Icon(Icons.location_on_outlined,
                          size: 20, color: Color(0xFF737782)),
                      const SizedBox(width: 10),
                      Expanded(
                          child: Text(
                              _address.isEmpty ? '주소 불러오는 중…' : _address,
                              style: const TextStyle(fontSize: 13)))
                    ])),
              ],
              if (_step == 1) ...[
                _heading('카테고리 선택', '이 장소에 가장 잘 맞는 카테고리를 선택해주세요.'),
                LayoutBuilder(
                    builder: (context, box) => GridView.count(
                          crossAxisCount:
                              MediaQuery.textScalerOf(context).scale(1) > 1.4
                                  ? 2
                                  : 3,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1,
                          children: vm.keywordIcons.keys
                              .map((keyword) => Semantics(
                                    selected: _keyword == keyword,
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _keyword = keyword),
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              border: Border.all(
                                                  color: _keyword == keyword
                                                      ? Colors.black
                                                      : const Color(0xFFE6E7EB),
                                                  width: _keyword == keyword
                                                      ? 1.5
                                                      : 1)),
                                          child: Stack(children: [
                                            Center(
                                                child: Column(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                  Icon(
                                                      placeKeywordIcon(keyword),
                                                      size: 30),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                      keyword == '음식점'
                                                          ? '맛집'
                                                          : keyword == '호텔'
                                                              ? '숙소'
                                                              : keyword,
                                                      style: const TextStyle(
                                                          fontSize: 13)),
                                                ])),
                                            if (_keyword == keyword)
                                              const Positioned(
                                                  top: 7,
                                                  right: 7,
                                                  child: Icon(
                                                      Icons.check_circle,
                                                      size: 20)),
                                          ])),
                                    ),
                                  ))
                              .toList(),
                        )),
              ],
              if (_step == 2) ...[
                _heading('저장할 리스트 선택', '이 장소를 어떤 리스트에 저장할까요?'),
                _listTile(
                    title: _creating ? '리스트 만드는 중…' : '새 리스트에 저장하기',
                    leading: const Icon(Icons.add_circle_outline, size: 30),
                    onTap: _creating ? null : _createList),
                if (_loadingLists)
                  const LinearProgressIndicator(color: Colors.black)
                else if (_listError)
                  TextButton(
                      onPressed: _loadLists, child: const Text('리스트 다시 불러오기'))
                else
                  ...vm.lists.map((list) {
                    final bookmarks = list['list_bookmarks'] as List? ?? [];
                    final title = bookmarks.isEmpty
                        ? list['name'].toString()
                        : bookmarks.first['title']?.toString() ??
                            list['name'].toString();
                    return _listTile(
                        title: list['name']?.toString() ?? '여행 리스트',
                        subtitle: '${bookmarks.length}개 장소',
                        selected: _listId == list['id'],
                        leading: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: SizedBox(
                                width: 48,
                                height: 48,
                                child: AddressPhotoPreview(
                                    address: '', title: title, size: 48))),
                        onTap: () =>
                            setState(() => _listId = list['id'].toString()));
                  }),
                _listTile(
                    title: '리스트 없이 저장',
                    subtitle: '내 지도에만 장소를 저장해요.',
                    leading: const Icon(Icons.map_outlined),
                    selected: _listId == null,
                    onTap: () => setState(() => _listId = null)),
              ],
            ])),
      ]),
    );
  }

  BoxDecoration get _border => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFFE1E3E7)));
  InputDecoration _input(String hint) => InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF9699A2)),
      contentPadding: const EdgeInsets.all(14),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE1E3E7))),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)));
  Widget _label(String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)));
  Widget _heading(String title, String subtitle) => Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(subtitle,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF6D7079), height: 1.5)),
      ]));
  Widget _listTile(
          {required String title,
          String? subtitle,
          required Widget leading,
          bool selected = false,
          VoidCallback? onTap}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 9),
          child: Material(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                      color:
                          selected ? Colors.black : const Color(0xFFE8E9EC))),
              child: ListTile(
                  onTap: onTap,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  leading: leading,
                  title: Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  subtitle: subtitle == null
                      ? null
                      : Text(subtitle,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF858892))),
                  trailing: selected
                      ? const Icon(Icons.check_circle, color: Colors.black)
                      : null)));
}
