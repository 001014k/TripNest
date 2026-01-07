import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/chat_recommendation_viewmodel.dart';
import '../design/app_design.dart';

class ChatRecommendationScreen extends StatelessWidget {
  final TextEditingController _controller = TextEditingController();

  ChatRecommendationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ChatRecommendationViewModel(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('AI 여행 플래너', style: AppDesign.headingSmall),
          backgroundColor: AppDesign.primaryBg,
          foregroundColor: AppDesign.primaryText,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => context.read<ChatRecommendationViewModel>().reset(),
            ),
          ],
        ),
        backgroundColor: AppDesign.primaryBg,
        body: Consumer<ChatRecommendationViewModel>(
          builder: (context, vm, child) {
            // 처음 진입 시: 모드 선택 화면
            if (vm.messages.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppDesign.spacing32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('어떤 도움을 드릴까요?', style: AppDesign.headingMedium),
                      const SizedBox(height: AppDesign.spacing32),
                      _buildModeButton(
                        context,
                        icon: Icons.place_rounded,
                        title: '장소 추천 받기',
                        subtitle: '특정 테마나 지역의 명소 추천',
                        onTap: () => vm.startNewSession('place'),
                      ),
                      const SizedBox(height: AppDesign.spacing24),
                      _buildModeButton(
                        context,
                        icon: Icons.calendar_today_rounded,
                        title: '여행 일정 짜기',
                        subtitle: '날짜별 상세 여행 계획 추천',
                        onTap: () => vm.startNewSession('itinerary'),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 채팅 시작 후
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(AppDesign.spacing16),
                    itemCount: vm.messages.length,
                    itemBuilder: (context, index) {
                      final msg = vm.messages[index];
                      final isUser = msg['role'] == 'user';

                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.8,
                          ),
                          decoration: BoxDecoration(
                            color: isUser ? AppDesign.travelBlue : AppDesign.cardBg,
                            borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
                            boxShadow: AppDesign.softShadow,
                          ),
                          child: Text(
                            msg['text']!,
                            style: TextStyle(
                              fontSize: 16,
                              color: isUser ? AppDesign.whiteText : AppDesign.primaryText,
                              height: 1.5,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 로딩 인디케이터
                if (vm.isLoading)
                  Padding(
                    padding: const EdgeInsets.all(AppDesign.spacing16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(AppDesign.travelBlue),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'AI가 추천을 준비 중입니다...',
                          style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
                        ),
                      ],
                    ),
                  ),

                // 입력 영역
                _buildInputArea(context, vm),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildModeButton(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
      }) {
    return Material(
      color: AppDesign.cardBg,
      borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.08),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDesign.radiusLarge),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Row(
            children: [
              Icon(icon, size: 48, color: AppDesign.travelBlue),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppDesign.headingSmall),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: AppDesign.bodyMedium.copyWith(color: AppDesign.secondaryText),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: AppDesign.subtleText, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea(BuildContext context, ChatRecommendationViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppDesign.spacing16),
      decoration: BoxDecoration(
        color: AppDesign.cardBg,
        border: Border(top: BorderSide(color: AppDesign.borderColor)),
        boxShadow: AppDesign.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(context, vm),
              decoration: InputDecoration(
                hintText: '메시지를 입력하세요...',
                hintStyle: AppDesign.bodyMedium.copyWith(color: AppDesign.subtleText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppDesign.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppDesign.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: AppDesign.travelBlue, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                filled: true,
                fillColor: AppDesign.primaryBg,
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            mini: true,
            onPressed: () => _sendMessage(context, vm),
            backgroundColor: AppDesign.travelBlue,
            elevation: 4,
            child: const Icon(Icons.send_rounded, color: AppDesign.whiteText),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context, ChatRecommendationViewModel vm) {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      _controller.clear();
      vm.sendMessage(text);
      // 키보드 내리기
      FocusScope.of(context).unfocus();
    }
  }
}