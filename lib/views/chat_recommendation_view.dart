import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_recommendation_viewmodel.dart';
import '../design/app_design.dart';
import '../viewmodels/mapsample_viewmodel.dart';

class ChatRecommendationScreen extends StatefulWidget {
  final MapSampleViewModel? mapSampleViewModel;
  const ChatRecommendationScreen({Key? key, this.mapSampleViewModel}) : super(key: key);

  @override
  State<ChatRecommendationScreen> createState() => _ChatRecommendationScreenState();
}

class _ChatRecommendationScreenState extends State<ChatRecommendationScreen>
    with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // 화면 진입 시 최근 추천 내역 로드
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatRecommendationViewModel>().loadRecentRecommendations();
    });
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeOut),
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatRecommendationViewModel(mapSampleViewModel: widget.mapSampleViewModel),
      child: Consumer<ChatRecommendationViewModel>(
        builder: (context, vm, child) {
          return Scaffold(
            body: Container(
              decoration: const BoxDecoration(
                gradient: AppDesign.backgroundGradient,
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    _buildAppBar(context, vm),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 400),
                        transitionBuilder: (Widget child, Animation<double> animation) {
                          return FadeTransition(opacity: animation, child: child);
                        },
                        child: vm.messages.isEmpty
                            ? _buildModeSelectionScreen(context, vm) // Stage 1
                            : _buildChatScreen(context, vm),         // Stage 2
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
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // 양 끝으로 배치
        children: [
          // 왼쪽 영역: 뒤로가기 + 타이틀
          Row(
            children: [
              _FeatureCard(
                padding: const EdgeInsets.all(10),
                color: AppDesign.cardBg,
                onTap: () {
                  if (vm.messages.isNotEmpty) {
                    // 채팅 중이라면 초기화하고 '목록/모드 선택' 상태로 돌아감
                    vm.resetChat();
                    // 여기서 Navigator.pop을 안 하면 지도 화면으로 안 나가고 채팅창 내에서 초기화만 됨
                  } else {
                    // 이미 초기 상태라면 지도 화면으로 나감
                    Navigator.pop(context);
                  }
                },
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  color: AppDesign.travelBlue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppDesign.glowShadow,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('AI 여행 플래너', style: AppDesign.headingSmall),
                  Text(
                    '맞춤형 여행 추천',
                    style: AppDesign.caption.copyWith(
                      color: AppDesign.secondaryText,
                    ),
                  ),
                ],
              ),
            ],
          ),

          // 오른쪽 영역: 액션 버튼 (초기화)
          if (vm.messages.isNotEmpty) // 메시지가 있을 때만 노출
            _FeatureCard(
              padding: const EdgeInsets.all(10),
              color: AppDesign.cardBg,
              onTap: () => _showResetDialog(context, vm), // 초기화 다이얼로그 호출
              child: const Icon(
                Icons.refresh_rounded, // 또는 delete_outline_rounded
                color: AppDesign.secondaryText,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, ChatRecommendationViewModel vm) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        ),
        backgroundColor: AppDesign.cardBg,
        title: const Text('대화 초기화', style: AppDesign.headingSmall),
        content: Text(
          '현재 대화를 종료하고 모드 선택 화면으로 돌아가시겠습니까?',
          style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              '취소',
              style: AppDesign.bodyMedium.copyWith(color: AppDesign.subtleText),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AppDesign.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  Navigator.pop(dialogContext);
                  vm.reset();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    '확인',
                    style: AppDesign.bodyMedium.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // _buildModeSelectionScreen 메서드 수정
  Widget _buildModeSelectionScreen(BuildContext context, ChatRecommendationViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _HeroCard(),
                const SizedBox(height: AppDesign.spacing24),
                _QuickStartGrid(onSelect: (preset) {
                  vm.startNewSession('place');
                  vm.sendMessage(preset);
                }),
                const SizedBox(height: AppDesign.spacing20),
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

  Widget _buildChatScreen(BuildContext context, ChatRecommendationViewModel vm) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(24),
            physics: const BouncingScrollPhysics(),
            itemCount: vm.messages.length,
            itemBuilder: (context, index) {
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
        if (vm.isLoading) _LoadingIndicator(),
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
    }
  }
}

// ================================
// 웰컴 헤더
// ================================
class _HeroCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppDesign.primaryText, // 다크 배경
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI 활성 badge — dot + 텍스트
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppDesign.travelBlue,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'AI 추천 활성',
                style: AppDesign.caption.copyWith(
                  color: AppDesign.travelBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing12),
          Text(
            '어디로 떠나고\n싶으세요?',
            style: AppDesign.headingMedium.copyWith(
              color: Colors.white,
              height: 1.25,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '아래 빠른 시작 부분에서 프리셋을 선택하거나\n대화를 시작해보세요',
            style: AppDesign.caption.copyWith(
              color: Colors.white.withOpacity(0.6),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStartGrid extends StatelessWidget {
  final Function(String preset) onSelect;

  const _QuickStartGrid({required this.onSelect});

  static const _items = [
    {
      'title': '근처 명소',
      'sub': '지금 위치 주변\n인기 장소 추천',
      'preset': '내 주변 인기 명소를 추천해줘',
      'icon': Icons.place_rounded,
      'gradient': [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
    },
    {
      'title': '테마 여행',
      'sub': '힐링·맛집·카페\n테마별 코스',
      'preset': '테마별 여행 코스를 추천해줘',
      'icon': Icons.explore_rounded,
      'gradient': [Color(0xFF10B981), Color(0xFF059669)],
    },
    {
      'title': '스테이 & 무드',
      'sub': '감성 숙소와\n취향 저격 공간',
      'preset': '인스타 감성의 독채 숙소와 사진 찍기 좋은 장소를 추천해줘',
      'icon': Icons.wb_sunny_rounded,
      'gradient': [Color(0xFFFF6B6B), Color(0xFFFFE066)],
    },
    {
      'title': '함께하는 여행',
      'sub': '친구·가족과\n함께할 코스',
      'preset': '친구들과 함께할 수 있는 여행 코스를 추천해줘',
      'icon': Icons.people_rounded,
      'gradient': [Color(0xFF8B5CF6), Color(0xFFEC4899)],
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '빠른 시작',
          style: AppDesign.caption.copyWith(
            color: AppDesign.secondaryText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppDesign.spacing12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.35,
          children: _items.map((item) {
            return _QuickStartCard(item: item, onTap: () {
              onSelect(item['preset'] as String);
            });
          }).toList(),
        ),
      ],
    );
  }
}

class _QuickStartCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  const _QuickStartCard({required this.item, required this.onTap});

  @override
  State<_QuickStartCard> createState() => _QuickStartCardState();
}

class _QuickStartCardState extends State<_QuickStartCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    final gradientColors = widget.item['gradient'] as List<Color>;

    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) { _controller.reverse(); widget.onTap(); },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scale,
        builder: (context, _) => Transform.scale(
          scale: _scale.value,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              border: Border.all(color: AppDesign.borderColor, width: 0.5),
              boxShadow: AppDesign.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: gradientColors,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    widget.item['icon'] as IconData,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const Spacer(),
                Text(
                  widget.item['title'] as String,
                  style: AppDesign.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.item['sub'] as String,
                  style: AppDesign.caption.copyWith(
                    color: AppDesign.subtleText,
                    height: 1.4,
                    fontSize: 11,
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

class _RecentChipsRow extends StatelessWidget {
  const _RecentChipsRow({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ChatRecommendationViewModel>();
    final recentItems = vm.recentRecommendations;

    if (recentItems.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '최근 추천',
          style: AppDesign.caption.copyWith(
            color: AppDesign.secondaryText,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: AppDesign.spacing8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: recentItems.map((item) {
            final String label = item['title'] ?? '추천 기록';

            return GestureDetector(
              onTap: () {
                // 💡 수정 완료: API 호출 없이 DB 데이터를 즉시 로드합니다.
                vm.loadRecentRecommendation(item);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppDesign.borderColor, width: 0.5),
                  boxShadow: AppDesign.softShadow.take(1).toList(),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppDesign.travelBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      label,
                      style: AppDesign.caption.copyWith(
                        color: AppDesign.secondaryText,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
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
                color: widget.accentColor.withOpacity(0.1),
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
                        color: widget.accentColor.withOpacity(0.3),
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
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
                          color: AppDesign.travelBlue.withOpacity(0.3),
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
                      color: AppDesign.travelBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppDesign.travelBlue.withOpacity(0.3),
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
                      ? AppDesign.travelBlue.withOpacity(0.2)
                      : Colors.black.withOpacity(0.05),
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
          if (!isUser && messageIndex == vm.messages.length - 1 && vm.pendingPlaces.isNotEmpty)
            _buildRecommendedPlacesCards(context),
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
                    onAdd: () {
                      vm.savePlaceToMap(
                        place,
                        context: context,   // ← 이거만 전달
                      ).then((_) {
                        // then 안에서 처리할 거 없으면 생략 가능
                      }).catchError((e) {
                        // catchError도 이미 함수 안에서 처리했으므로 생략 가능
                      });
                    },
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
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppDesign.borderColor.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            place['title'] ?? '장소 이름',
            style: AppDesign.bodyLarge.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            place['snippet'] ?? place['address'] ?? '',
            style: AppDesign.caption.copyWith(color: AppDesign.secondaryText),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: onAdd,  // ← 여기서 vm.savePlaceToMap() 호출됨
                icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                label: const Text("지도에 추가"),
                style: TextButton.styleFrom(
                  foregroundColor: AppDesign.travelBlue,
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
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
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 24,
        vertical: 16,
      ),
      decoration: BoxDecoration(
        color: AppDesign.cardBg.withOpacity(0.95),
        border: Border(
          top: BorderSide(
            color: AppDesign.borderColor.withOpacity(0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: AppDesign.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'AI가 추천을 준비하고 있어요...',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
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

  const _PremiumInputArea({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        border: Border(
          top: BorderSide(
            color: AppDesign.borderColor.withOpacity(0.5),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppDesign.primaryBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppDesign.borderColor,
                    width: 1.5,
                  ),
                ),
                child: TextField(
                  controller: controller,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => onSend(),
                  maxLines: null,
                  style: AppDesign.bodyMedium,
                  decoration: InputDecoration(
                    hintText: '메시지를 입력하세요...',
                    hintStyle: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.subtleText,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            _FeatureCard(
              padding: const EdgeInsets.all(14),
              gradient: AppDesign.primaryGradient,
              onTap: onSend,
              child: const Icon(
                Icons.send_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================================
// 기능 카드 (애니메이션 포함)
// ================================
class _FeatureCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Gradient? gradient;
  final VoidCallback? onTap;

  const _FeatureCard({
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.color,
    this.gradient,
    this.onTap,
  });

  @override
  State<_FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<_FeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shadowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _shadowAnimation = Tween<double>(begin: 1.0, end: 0.5).animate(
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
      onTapDown: widget.onTap != null ? (_) => _controller.forward() : null,
      onTapUp: widget.onTap != null ? (_) {
        _controller.reverse();
        widget.onTap!();
      } : null,
      onTapCancel: widget.onTap != null ? () => _controller.reverse() : null,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: widget.padding,
            decoration: BoxDecoration(
              color: widget.gradient == null
                  ? (widget.color ?? AppDesign.cardBg)
                  : null,
              gradient: widget.gradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppDesign.softShadow.map((shadow) {
                return shadow.copyWith(
                  blurRadius: shadow.blurRadius * _shadowAnimation.value,
                  color: shadow.color.withOpacity(
                    shadow.color.opacity * _shadowAnimation.value,
                  ),
                );
              }).toList(),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}