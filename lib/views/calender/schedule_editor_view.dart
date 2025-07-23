import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/calender/schedule_editor_viewmodel.dart';

class ScheduleEditorView extends StatelessWidget {
  const ScheduleEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return ChangeNotifierProvider(
      create: (_) {
        final vm = ScheduleEditorViewModel();
        vm.initializeWith(event);
        return vm;
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.black26,
          title: Consumer<ScheduleEditorViewModel>(
            builder: (context, vm, _) => Text(
              vm.isEditMode ? "여정 수정하기" : "새 여행 일정",
              style: const TextStyle(color: Colors.white),
            ),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: Consumer<ScheduleEditorViewModel>(
          builder: (context, vm, _) => Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildCard(
                      icon: Icons.title,
                      label: '제목',
                      child: TextFormField(
                        initialValue: vm.title,
                        onChanged: (val) => vm.title = val,
                        decoration: const InputDecoration(
                          hintText: '어디로 가시나요?',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _buildCard(
                      icon: Icons.calendar_today,
                      label: '날짜',
                      child: ListTile(
                        title: Text(vm.date != null
                            ? '${vm.date!.year}-${vm.date!.month}-${vm.date!.day}'
                            : '날짜를 선택해주세요'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          final selected = await showDatePicker(
                            context: context,
                            initialDate: vm.date ?? DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          );
                          if (selected != null) {
                            vm.date = selected;
                            vm.notifyListeners();
                          }
                        },
                      ),
                    ),
                    _buildCard(
                      icon: Icons.access_time,
                      label: '시간',
                      child: ListTile(
                        title: Text(vm.time != null
                            ? vm.time!.format(context)
                            : '시간을 선택해주세요'),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () async {
                          final selected = await showTimePicker(
                            context: context,
                            initialTime: vm.time ?? TimeOfDay.now(),
                          );
                          if (selected != null) {
                            vm.time = selected;
                            vm.notifyListeners();
                          }
                        },
                      ),
                    ),
                    _buildCard(
                      icon: Icons.place,
                      label: '장소',
                      child: TextFormField(
                        initialValue: vm.location,
                        onChanged: (val) => vm.location = val,
                        decoration: const InputDecoration(
                          hintText: '여행 장소를 입력하세요',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _buildCard(
                      icon: Icons.list,
                      label: '리스트',
                      child: DropdownButtonFormField<String>(
                        value: vm.selectedListId,
                        decoration: const InputDecoration(
                          hintText: '관련 리스트 선택',
                          border: InputBorder.none,
                        ),
                        items: vm.userLists.map((item) {
                          return DropdownMenuItem<String>(
                            value: item['id'],
                            child: Text(item['name']),
                          );
                        }).toList(),
                        onChanged: (val) {
                          vm.selectedListId = val;
                          vm.notifyListeners();
                        },
                      ),
                    ),
                    _buildCard(
                      icon: Icons.attach_money,
                      label: '예산',
                      child: TextFormField(
                        initialValue: vm.budget,
                        keyboardType: TextInputType.number,
                        onChanged: (val) => vm.budget = val,
                        decoration: const InputDecoration(
                          hintText: '예산 입력 (원)',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _buildCard(
                      icon: Icons.notes,
                      label: '메모',
                      child: TextFormField(
                        initialValue: vm.memo,
                        maxLines: 3,
                        onChanged: (val) => vm.memo = val,
                        decoration: const InputDecoration(
                          hintText: '메모를 남겨보세요',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: vm.alarm,
                      onChanged: (val) {
                        vm.alarm = val;
                        vm.notifyListeners();
                      },
                      title: const Text('30분 전 알림 설정'),
                      secondary: const Icon(Icons.notifications_active),
                    ),
                    SwitchListTile(
                      value: vm.shareWithFriends,
                      onChanged: (val) {
                        vm.shareWithFriends = val;
                        vm.notifyListeners();
                      },
                      title: const Text('친구와 공유하기'),
                      secondary: const Icon(Icons.group),
                    ),
                  ],
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.check),
                    label: const Text('저장하기'),
                    onPressed: () async {
                      await vm.saveSchedule();
                      Navigator.pop(context, true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black26,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String label,
    required Widget child,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.lightBlueAccent),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
