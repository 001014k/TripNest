import '../../navigation/app_page_route.dart';
import '../../widgets/common/app_overlays.dart';
import '../../widgets/navigation/tripnest_navigation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../widgets/places/address_photo_preview.dart';
import '../../viewmodels/planner/chat_recommendation_viewmodel.dart';
import '../../design/app_design.dart';
import '../../viewmodels/map/mapsample_viewmodel.dart';
import '../markers/markercreationscreen_view.dart';

class ChatRecommendationScreen extends StatefulWidget {
  const ChatRecommendationScreen({super.key});

  @override
  State<ChatRecommendationScreen> createState() =>
      _ChatRecommendationScreenState();
}

class _ChatRecommendationScreenState extends State<ChatRecommendationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // 새 질문과 AI 응답이 보이도록 대화의 마지막으로 이동합니다.
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scheduleScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToBottom();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = ChatRecommendationViewModel();
        // 생성 직후 바로 로드
        vm.loadRecentRecommendations();
        return vm;
      },
      child: Consumer<ChatRecommendationViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.white, Color(0xFFFAFAFB)],
                ),
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, vm),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                              opacity: animation, child: child);
                        },
                        child: vm.messages.isEmpty
                            ? _buildModeSelectionScreen(context, vm) // Stage 1
                            : _buildChatScreen(context, vm), // Stage 2
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

  Widget _buildAppBar(BuildContext context, ChatRecommendationViewModel vm) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 16, 14),
      child: TripNestHeader(
        onBack: () {
          if (vm.messages.isNotEmpty) {
            vm.resetChat();
          } else {
            Navigator.pop(context);
          }
        },
        trailing: vm.messages.isNotEmpty
            ? IconButton(
                tooltip: '대화 초기화',
                onPressed: () => _showResetDialog(context, vm),
                icon: const Icon(Icons.refresh_rounded),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  void _showResetDialog(
      BuildContext context, ChatRecommendationViewModel vm) async {
    final confirmed = await showDialog<bool>(
        context: context,
        builder: (_) => const AppConfirmDialog(
            title: '대화를 초기화할까요?',
            message: '현재 대화를 종료하고 모드 선택 화면으로 돌아갑니다.',
            confirmLabel: '초기화',
            icon: Icons.refresh_rounded));
    if (confirmed == true && context.mounted) vm.reset();
  }

  // _buildModeSelectionScreen 메서드 수정
  Widget _buildModeSelectionScreen(
      BuildContext context, ChatRecommendationViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 22, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AI 여행 플래너',
                    style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                        letterSpacing: -1.2)),
                const SizedBox(height: 8),
                const Text('취향에 맞는 여행을 함께 계획해요.',
                    style: TextStyle(
                        fontSize: 17, color: Color(0xFF60636E), height: 1.5)),
                const SizedBox(height: 24),
                _HeroCard(),
                const SizedBox(height: 12),
                _QuickStartGrid(
                  onSelect: (preset, {bool isNearby = false}) {
                    vm.startNewSession('place');
                    vm.sendMessage(preset, isNearbySearch: isNearby);
                  },
                ),
                const SizedBox(height: 28),
                _RecentChipsRow(),
                // 기존에 여기 있던 _PremiumInputArea를 삭제
              ],
            ),
          ),
        ),
        // 입력창을 Expanded 외부(Column 하단)에 배치하여 고정
        _PremiumInputArea(
          controller: _controller,
          onSend: () => _sendMessage(context, vm),
        ),
      ],
    );
  }

  Widget _buildChatScreen(
      BuildContext context, ChatRecommendationViewModel vm) {
    final isPreparingResponse = vm.isLoading &&
        vm.messages.isNotEmpty &&
        vm.messages.last['role'] == 'bot' &&
        (vm.messages.last['text']?.trim().isEmpty ?? true);

    if (isPreparingResponse) {
      _scheduleScrollToBottom();
    }

    // 답변을 받을 빈 봇 메시지는 준비 중 말풍선으로 대체해 중복 표시를 막습니다.
    final visibleMessageCount =
        vm.messages.length - (isPreparingResponse ? 1 : 0);

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: visibleMessageCount + (isPreparingResponse ? 1 : 0),
            itemBuilder: (context, index) {
              if (isPreparingResponse && index == visibleMessageCount) {
                return const _LoadingIndicator();
              }

              final msg = vm.messages[index];
              final isUser = msg['role'] == 'user';
              return _ChatMessageBubble(
                message: msg['text']!,
                isUser: isUser,
                messageIndex: index,
                vm: vm,
              );
            },
          ),
        ),
        _PremiumInputArea(
          controller: _controller,
          onSend: () => _sendMessage(context, vm),
        ),
      ],
    );
  }

  void _sendMessage(BuildContext context, ChatRecommendationViewModel vm) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      vm.sendMessage(text);
      FocusScope.of(context).unfocus();
      _scheduleScrollToBottom();

      // 입력창이 닫히는 애니메이션 뒤에도 마지막 메시지가 보이게 한 번 더 맞춥니다.
      Future<void>.delayed(const Duration(milliseconds: 260), () {
        if (mounted) {
          _scrollToBottom();
        }
      });
    }
  }
}

// ================================
// 웰컴 헤더
// ================================
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 28),
        decoration: _plannerCardDecoration,
        child: Row(children: [
          const SizedBox(
              width: 82,
              height: 64,
              child: CustomPaint(painter: _PlannerMapPainter())),
          const SizedBox(width: 18),
          const Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('어디로 떠나고 싶으세요?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -.6)),
              SizedBox(height: 10),
              Text('원하는 지역이나 여행 테마를 알려주세요.',
                  style: TextStyle(
                      fontSize: 13, color: Color(0xFF666975), height: 1.5)),
            ],
          )),
        ]),
      );
}

final _plannerCardDecoration = BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(15),
  border: Border.all(color: const Color(0xFFECEDEF)),
  boxShadow: const [
    BoxShadow(color: Color(0x05000000), blurRadius: 18, offset: Offset(0, 5))
  ],
);

class _PlannerMapPainter extends CustomPainter {
  const _PlannerMapPainter();
  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 82, size.height / 64);
    final map = Path()
      ..moveTo(4, 20)
      ..quadraticBezierTo(4, 16, 9, 15)
      ..lineTo(28, 9)
      ..lineTo(53, 17)
      ..lineTo(74, 10)
      ..quadraticBezierTo(78, 9, 78, 14)
      ..lineTo(78, 55)
      ..lineTo(54, 63)
      ..lineTo(29, 56)
      ..lineTo(4, 63)
      ..close();
    canvas.drawPath(map, Paint()..color = const Color(0xFFF4F4F5));
    final route = Path()
      ..moveTo(13, 51)
      ..cubicTo(18, 25, 34, 28, 40, 40)
      ..cubicTo(52, 60, 76, 35, 62, 27);
    final ink = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (final metric in route.computeMetrics()) {
      for (double d = 0; d < metric.length; d += 7) {
        canvas.drawPath(metric.extractPath(d, d + 3), ink);
      }
    }
    final pin = Path()
      ..moveTo(48, 32)
      ..cubicTo(42, 24, 38, 19, 38, 13)
      ..cubicTo(38, -1, 58, -1, 58, 13)
      ..cubicTo(58, 19, 53, 26, 48, 32)
      ..close();
    canvas.drawPath(pin, Paint()..color = Colors.white);
    canvas.drawPath(pin, ink);
    canvas.drawCircle(const Offset(48, 12), 4, ink);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PlannerMapPainter oldDelegate) => false;
}

class _QuickStartGrid extends StatelessWidget {
  final Function(String preset, {bool isNearby}) onSelect;
  const _QuickStartGrid({required this.onSelect});

  static const _items = [
    (
      '근처 명소',
      '내 주변 인기 장소',
      '내 주변 인기 명소를 추천해줘',
      Icons.location_on_outlined,
      true
    ),
    (
      '테마 여행',
      '힐링 · 맛집 · 카페',
      '테마별 여행 코스를 추천해줘',
      Icons.restaurant_outlined,
      false
    ),
    (
      '스테이 & 무드',
      '감성 숙소와 공간',
      '인스타 감성의 독채 숙소와 사진 찍기 좋은 장소를 추천해줘',
      Icons.home_outlined,
      false
    ),
    (
      '함께하는 여행',
      '친구 · 가족과 함께',
      '친구들과 함께할 수 있는 여행 코스를 추천해줘',
      Icons.people_outline_rounded,
      false
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth < 300 || scale > 1.4 ? 1 : 2;
      return GridView.count(
        padding: EdgeInsets.zero,
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: (constraints.maxWidth - (columns - 1) * 10) /
            columns /
            (144 + (scale - 1) * 90),
        children: _items
            .map((item) => Container(
                  decoration: _plannerCardDecoration,
                  child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => onSelect(item.$3, isNearby: item.$5),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(item.$4, size: 34, color: Colors.black),
                                const Spacer(),
                                Row(children: [
                                  Expanded(
                                      child: Text(item.$1,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: -.6))),
                                  const Icon(Icons.chevron_right_rounded,
                                      size: 21, color: Color(0xFF5E626C)),
                                ]),
                                const SizedBox(height: 5),
                                Text(item.$2,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF666975))),
                              ]),
                        ),
                      )),
                ))
            .toList(),
      );
    });
  }
}

class _RecentChipsRow extends StatelessWidget {
  const _RecentChipsRow();
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatRecommendationViewModel>();
    final items = vm.recentRecommendations;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('최근 추천',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ActionChip(
                        label: Text(item['title'] ?? '추천 기록'),
                        onPressed: () => vm.loadRecentRecommendation(item),
                        backgroundColor: const Color(0xFFF5F5F6),
                        side: const BorderSide(color: Color(0xFFE6E7EA)),
                        shape: const StadiumBorder(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 10),
                        labelStyle: const TextStyle(
                            fontSize: 14, color: Color(0xFF202020)),
                      ),
                    ))
                .toList(),
          )),
    ]);
  }
}

// ================================
// 프리미엄 모드 카드
// ================================
class _PremiumModeCard extends StatefulWidget {
  final Gradient gradient;
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  const _PremiumModeCard({
    required this.gradient,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  @override
  State<_PremiumModeCard> createState() => _PremiumModeCardState();
}

class _PremiumModeCardState extends State<_PremiumModeCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
              boxShadow: AppDesign.elevatedShadow,
              border: Border.all(
                color: widget.accentColor.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    boxShadow: [
                      BoxShadow(
                        color: widget.accentColor.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: AppDesign.headingSmall),
                      const SizedBox(height: 6),
                      Text(
                        widget.subtitle,
                        style: AppDesign.bodyMedium.copyWith(
                          color: AppDesign.secondaryText,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppDesign.lightGray,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios,
                    color: AppDesign.subtleText,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ================================
// 채팅 메시지 버블
// ================================
class _ChatMessageBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final int messageIndex;
  final ChatRecommendationViewModel vm;

  const _ChatMessageBubble({
    required this.message,
    required this.isUser,
    required this.messageIndex,
    required this.vm,
  });

  Future<void> _savePlaceToMap(
      BuildContext context, Map<String, dynamic> place) async {
    try {
      final lat = (place['lat'] as num).toDouble();
      final lng = (place['lng'] as num).toDouble();
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        AppPageRoute(
          motion: AppMotion.editor,
          builder: (_) => MarkerCreationScreen(
            initialTitle: place['name'] ?? place['title'] ?? '',
            initialAddress: place['address'] ?? '',
            initialLatLng: LatLng(lat, lng),
          ),
        ),
      );
      if (!context.mounted || result == null) return;
      final mapViewModel = context.read<MapSampleViewModel>();
      final saved = await mapViewModel.addMarker(
        title: result['title'] as String?,
        snippet: result['snippet'] as String?,
        position: LatLng(lat, lng),
        keyword: result['keyword'] as String,
        address: result['address'] as String? ?? place['address'] ?? '',
        listId: result['listId'] as String?,
        onTapCallback: (markerId) => mapViewModel.onMarkerTapped(markerId),
      );
      if (!context.mounted) return;
      if (saved) vm.markPlaceSaved(place);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(saved
                ? "${result['title']}이(가) 지도에 추가되었습니다."
                : '마커를 저장하지 못했습니다. 다시 시도해주세요.')),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('마커를 저장하지 못했습니다. 다시 시도해주세요.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // 아바타와 이름
          Padding(
            padding: EdgeInsets.only(
              left: isUser ? 0 : 4,
              right: isUser ? 4 : 0,
              bottom: 8,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isUser) ...[
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      gradient: AppDesign.primaryGradient,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppDesign.travelBlue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.smart_toy_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AI 어시스턴트',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (isUser) ...[
                  Text(
                    '나',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.secondaryText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppDesign.travelBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppDesign.travelBlue.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 16,
                      color: AppDesign.travelBlue,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // 메시지 버블
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              gradient: isUser ? AppDesign.primaryGradient : null,
              color: isUser ? null : AppDesign.cardBg,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(
                  isUser ? AppDesign.radiusLarge : AppDesign.radiusSmall,
                ),
                topRight: Radius.circular(
                  isUser ? AppDesign.radiusSmall : AppDesign.radiusLarge,
                ),
                bottomLeft: const Radius.circular(AppDesign.radiusLarge),
                bottomRight: const Radius.circular(AppDesign.radiusLarge),
              ),
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? AppDesign.travelBlue.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                  spreadRadius: -2,
                ),
              ],
            ),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 15,
                color: isUser ? Colors.white : AppDesign.primaryText,
                height: 1.6,
                letterSpacing: 0.2,
              ),
            ),
          ),
          // === AI 응답 완료 시 추천 카드 + 자동 스크롤 ===
          if (!isUser &&
              messageIndex == vm.messages.length - 1 &&
              vm.pendingPlaces.isNotEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildRecommendedPlacesCards(context),

                // 자동 스크롤
                Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (context.mounted) {
                        final state = context.findAncestorStateOfType<
                            _ChatRecommendationScreenState>();
                        state?._scrollToBottom();
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendedPlacesCards(BuildContext context) {
    final places = vm.pendingPlaces;

    if (places.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "추천 장소",
            style: AppDesign.caption.copyWith(
              color: AppDesign.travelBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: places.map((place) {
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _PlaceCard(
                    place: place,
                    onAdd: () => _savePlaceToMap(context, place),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// 파일 하단이나 적당한 위치에 추가
class _PlaceCard extends StatelessWidget {
  final Map<String, dynamic> place;
  final VoidCallback onAdd;

  const _PlaceCard({
    required this.place,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final title = place['title']?.toString() ?? '장소 이름';
    final address =
        place['address']?.toString() ?? place['snippet']?.toString() ?? '';
    final rating = (place['rating'] as num?)?.toDouble();

    return Container(
      width: 310,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
        border: Border.all(color: AppDesign.borderColor),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                child: SizedBox(
                  width: 84,
                  height: 84,
                  child: AddressPhotoPreview(
                    address: address,
                    title: title,
                    size: 84,
                  ),
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppDesign.headingSmall.copyWith(fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (rating != null) ...[
                      const SizedBox(height: AppDesign.spacing6),
                      Row(
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 18,
                            color: AppDesign.travelOrange,
                          ),
                          const SizedBox(width: AppDesign.spacing4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: AppDesign.bodyMedium.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: AppDesign.spacing8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: AppDesign.subtleText,
                        ),
                        const SizedBox(width: AppDesign.spacing4),
                        Expanded(
                          child: Text(
                            address,
                            style: AppDesign.caption.copyWith(
                              color: AppDesign.secondaryText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_location_alt_rounded, size: 18),
              label: const Text('지도에 추가'),
              style: FilledButton.styleFrom(
                backgroundColor: AppDesign.primary,
                foregroundColor: AppDesign.whiteText,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ================================
// 로딩 인디케이터
// ================================
class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppDesign.cardBg.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(18),
          border:
              Border.all(color: AppDesign.borderColor.withValues(alpha: 0.7)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: AppDesign.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'AI가 답변을 준비하고 있어요',
              style: AppDesign.bodyMedium.copyWith(
                color: AppDesign.secondaryText,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// 프리미엄 입력 영역
// ================================
class _PremiumInputArea extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  const _PremiumInputArea({required this.controller, required this.onSend});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Color(0xFFF0F0F2)))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
              child: TextField(
            controller: controller,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
            minLines: 1,
            maxLines: 4,
            style: const TextStyle(fontSize: 15),
            decoration: InputDecoration(
              hintText: '여행하고 싶은 곳을 알려주세요.',
              hintStyle:
                  const TextStyle(fontSize: 14, color: Color(0xFF9B9EA8)),
              filled: true,
              fillColor: const Color(0xFFF5F5F6),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: const BorderSide(color: Color(0xFFDADCE0))),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          )),
          const SizedBox(width: 8),
          IconButton.filled(
            tooltip: '메시지 보내기',
            onPressed: onSend,
            style: IconButton.styleFrom(
                backgroundColor: Colors.black,
                foregroundColor: Colors.white,
                fixedSize: const Size(44, 44)),
            icon: const Icon(Icons.arrow_upward_rounded, size: 29),
          ),
        ]),
      );
}
