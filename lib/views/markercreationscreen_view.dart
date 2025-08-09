import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../viewmodels/markercreationscreen_viewmodel.dart';
import '../design/app_design.dart'; // AppDesign 임포트 추가

class MarkerCreationScreen extends StatefulWidget {
  final LatLng initialLatLng;

  MarkerCreationScreen({required this.initialLatLng});

  @override
  _MarkerCreationScreenState createState() => _MarkerCreationScreenState();
}

class _MarkerCreationScreenState extends State<MarkerCreationScreen>
    with TickerProviderStateMixin {
  TextEditingController _titleController = TextEditingController();
  TextEditingController _snippetController = TextEditingController();
  String? _selectedKeyword;
  String? _selectedListId;
  File? _image;
  String _address = '주소 불러오는 중...';

  late AnimationController _fadeAnimationController;
  late Animation<double> _fadeAnimation;
  late AnimationController _slideAnimationController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadAddress();
    _loadUserLists();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeAnimationController, curve: Curves.easeOut),
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideAnimationController, curve: Curves.easeOutCubic),
    );

    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  Future<void> _loadAddress() async {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context, listen: false);
    final result = await viewModel.getAddressFromCoordinates(
      widget.initialLatLng.latitude,
      widget.initialLatLng.longitude,
    );
    setState(() {
      _address = result;
    });
  }

  Future<void> _loadUserLists() async {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context, listen: false);
    await viewModel.fetchUserLists();
    if (viewModel.lists.isNotEmpty) {
      setState(() {
        _selectedListId = viewModel.lists.first['id'];
      });
    }
  }

  @override
  void dispose() {
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    _titleController.dispose();
    _snippetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MarkerCreationScreenViewModel>(context);
    final List<String> keywords = viewModel.keywordIcons.keys.toList();
    final List<Map<String, dynamic>> userLists = viewModel.lists;

    return Scaffold(
      backgroundColor: AppDesign.primaryBg,
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppDesign.backgroundGradient,
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 프리미엄 헤더
                SliverToBoxAdapter(
                  child: _buildPremiumHeader(context),
                ),

                // 메인 폼 컨텐츠
                SliverToBoxAdapter(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(AppDesign.spacing20),
                      child: Column(
                        children: [
                          // 위치 정보 카드
                          _buildLocationCard(),
                          const SizedBox(height: AppDesign.spacing20),

                          // 기본 정보 입력 카드
                          _buildBasicInfoCard(),
                          const SizedBox(height: AppDesign.spacing20),

                          // 카테고리 선택 카드
                          _buildCategoryCard(keywords, viewModel),
                          const SizedBox(height: AppDesign.spacing20),

                          // 리스트 선택 카드
                          _buildListSelectionCard(userLists),
                          const SizedBox(height: AppDesign.spacing32),

                          // 저장 버튼
                          _buildSaveButton(),
                          const SizedBox(height: AppDesign.spacing40),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // 뒤로가기 버튼
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppDesign.cardBg,
                  borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                  boxShadow: AppDesign.softShadow,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: AppDesign.primaryText,
                      size: 20,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              // 지도 아이콘
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing12),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: AppDesign.glowShadow,
                ),
                child: const Icon(
                  Icons.add_location_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing32),
          // 타이틀 섹션
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppDesign.travelBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppDesign.travelBlue.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Text(
              '새로운 장소',
              style: AppDesign.caption.copyWith(
                color: AppDesign.travelBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spacing12),
          const Text('마커 만들기', style: AppDesign.headingXL),
          const SizedBox(height: AppDesign.spacing8),
          Text(
            '여행지 정보를 입력해주세요 ✏️',
            style: AppDesign.bodyLarge.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing20),
      decoration: BoxDecoration(
        gradient: AppDesign.sunsetGradient,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppDesign.sunsetGradientStart.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
            ),
            child: const Icon(
              Icons.location_on_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppDesign.spacing16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '선택한 위치',
                  style: AppDesign.caption.copyWith(
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppDesign.spacing4),
                Text(
                  _address,
                  style: AppDesign.bodyMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard() {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  gradient: AppDesign.primaryGradient,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: const Icon(
                  Icons.edit_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Text(
                '기본 정보',
                style: AppDesign.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing24),

          // 제목 입력
          Text(
            '장소 이름',
            style: AppDesign.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesign.primaryText,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Container(
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              border: Border.all(
                color: AppDesign.borderColor,
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: _titleController,
              style: AppDesign.bodyMedium,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.place_outlined,
                  color: AppDesign.travelBlue,
                  size: 20,
                ),
                hintText: '예: 에펠탑, 루브르 박물관',
                hintStyle: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.subtleText,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing16,
                  vertical: AppDesign.spacing16,
                ),
              ),
            ),
          ),
          const SizedBox(height: AppDesign.spacing20),

          // 설명 입력
          Text(
            '설명',
            style: AppDesign.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: AppDesign.primaryText,
            ),
          ),
          const SizedBox(height: AppDesign.spacing8),
          Container(
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              border: Border.all(
                color: AppDesign.borderColor,
                width: 1,
              ),
            ),
            child: TextFormField(
              controller: _snippetController,
              style: AppDesign.bodyMedium,
              maxLines: 3,
              decoration: InputDecoration(
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(
                    left: AppDesign.spacing12,
                    right: AppDesign.spacing12,
                    bottom: 40,
                  ),
                  child: Icon(
                    Icons.notes_rounded,
                    color: AppDesign.travelPurple,
                    size: 20,
                  ),
                ),
                hintText: '이 장소에 대한 메모나 특별한 기억을 남겨주세요',
                hintStyle: AppDesign.bodyMedium.copyWith(
                  color: AppDesign.subtleText,
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
      ),
    );
  }

  Widget _buildCategoryCard(List<String> keywords, MarkerCreationScreenViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  gradient: AppDesign.greenGradient,
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: const Icon(
                  Icons.category_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Text(
                '카테고리',
                style: AppDesign.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing20),

          // 키워드 선택 그리드
          Text(
            '이 장소의 카테고리를 선택하세요',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),
          Wrap(
            spacing: AppDesign.spacing12,
            runSpacing: AppDesign.spacing12,
            children: keywords.map((keyword) {
              final isSelected = _selectedKeyword == keyword;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedKeyword = keyword;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesign.spacing16,
                    vertical: AppDesign.spacing12,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected ? AppDesign.primaryGradient : null,
                    color: isSelected ? null : AppDesign.lightGray,
                    borderRadius: BorderRadius.circular(AppDesign.radiusXL),
                    border: Border.all(
                      color: isSelected
                          ? AppDesign.travelBlue.withOpacity(0.3)
                          : AppDesign.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected ? AppDesign.glowShadow : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        viewModel.keywordIcons[keyword],
                        color: isSelected ? Colors.white : AppDesign.secondaryText,
                        size: 18,
                      ),
                      const SizedBox(width: AppDesign.spacing8),
                      Text(
                        keyword,
                        style: AppDesign.bodyMedium.copyWith(
                          color: isSelected ? Colors.white : AppDesign.primaryText,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildListSelectionCard(List<Map<String, dynamic>> userLists) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing24),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        boxShadow: AppDesign.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 섹션 헤더
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesign.spacing8),
                decoration: BoxDecoration(
                  color: AppDesign.travelOrange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
                ),
                child: Icon(
                  Icons.folder_rounded,
                  color: AppDesign.travelOrange,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppDesign.spacing12),
              Text(
                '리스트에 추가',
                style: AppDesign.headingSmall,
              ),
            ],
          ),
          const SizedBox(height: AppDesign.spacing20),

          Text(
            '이 마커를 추가할 리스트를 선택하세요',
            style: AppDesign.bodyMedium.copyWith(
              color: AppDesign.secondaryText,
            ),
          ),
          const SizedBox(height: AppDesign.spacing16),

          Container(
            decoration: BoxDecoration(
              color: AppDesign.lightGray,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              border: Border.all(
                color: AppDesign.borderColor,
                width: 1,
              ),
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedListId,
              isExpanded: true,
              style: AppDesign.bodyMedium,
              icon: Icon(
                Icons.expand_more_rounded,
                color: AppDesign.travelOrange,
              ),
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Icons.list_rounded,
                  color: AppDesign.travelOrange,
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppDesign.spacing16,
                  vertical: AppDesign.spacing4,
                ),
              ),
              dropdownColor: AppDesign.cardBg,
              borderRadius: BorderRadius.circular(AppDesign.radiusMedium),
              items: [
                DropdownMenuItem<String>(
                  value: null,
                  child: Text(
                    '리스트에 추가하지 않음',
                    style: AppDesign.bodyMedium.copyWith(
                      color: AppDesign.subtleText,
                    ),
                  ),
                ),
                ...userLists.map((list) {
                  return DropdownMenuItem<String>(
                    value: list['id'],
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: AppDesign.spacing8),
                          decoration: BoxDecoration(
                            color: AppDesign.travelOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        Text(
                          list['name'],
                          style: AppDesign.bodyMedium,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: (String? newValue) {
                setState(() {
                  _selectedListId = newValue;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTapDown: (_) {},
      onTapUp: (_) {
        if (_titleController.text.isEmpty) {
          _showErrorSnackBar('장소 이름을 입력해주세요');
          return;
        }
        if (_selectedKeyword == null) {
          _showErrorSnackBar('카테고리를 선택해주세요');
          return;
        }

        Navigator.pop(context, {
          'title': _titleController.text,
          'snippet': _snippetController.text,
          'keyword': _selectedKeyword,
          'image': _image,
          'listId': _selectedListId,
          'address': _address,
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppDesign.spacing20),
        decoration: BoxDecoration(
          gradient: AppDesign.primaryGradient,
          borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
          boxShadow: [
            ...AppDesign.elevatedShadow,
            BoxShadow(
              color: AppDesign.travelBlue.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.save_rounded,
              color: Colors.white,
              size: 24,
            ),
            const SizedBox(width: AppDesign.spacing12),
            Text(
              '마커 저장하기',
              style: AppDesign.bodyLarge.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: AppDesign.spacing8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesign.radiusSmall),
        ),
      ),
    );
  }
}