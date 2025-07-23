import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/calender/schedule_editor_viewmodel.dart';

class ScheduleEditorView extends StatelessWidget {
  const ScheduleEditorView({super.key});

  @override
  Widget build(BuildContext context) {
    final event = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    return ChangeNotifierProvider(
      create: (_) => ScheduleEditorViewModel()..initializeWith(event),
      child: Scaffold(
        appBar: AppBar(
          title: Consumer<ScheduleEditorViewModel>(
            builder: (context, vm, _) => Text(vm.isEditMode ? "일정 수정" : "새 일정 추가"),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Consumer<ScheduleEditorViewModel>(
            builder: (context, vm, _) => ListView(
              children: [
                TextField(
                  decoration: const InputDecoration(labelText: '제목'),
                  onChanged: (value) => vm.title = value,
                  controller: TextEditingController(text: vm.title),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text(vm.date != null
                      ? '날짜: ${vm.date!.toLocal().toIso8601String().split("T")[0]}'
                      : '날짜 선택'),
                  trailing: const Icon(Icons.calendar_today),
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
                const SizedBox(height: 12),
                ListTile(
                  title: Text(vm.time != null
                      ? '시간: ${vm.time!.format(context)}'
                      : '시간 선택'),
                  trailing: const Icon(Icons.access_time),
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
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: '장소'),
                  onChanged: (value) => vm.location = value,
                  controller: TextEditingController(text: vm.location),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField(
                  value: vm.category,
                  items: const [
                    DropdownMenuItem(value: '관광지', child: Text('🏰 관광지')),
                    DropdownMenuItem(value: '식사', child: Text('🍽️ 식사')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      vm.category = value;
                      vm.notifyListeners();
                    }
                  },
                  decoration: const InputDecoration(labelText: '카테고리'),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: '예산'),
                  onChanged: (value) => vm.budget = value,
                  controller: TextEditingController(text: vm.budget),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(labelText: '메모'),
                  maxLines: 3,
                  onChanged: (value) => vm.memo = value,
                  controller: TextEditingController(text: vm.memo),
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: vm.alarm,
                  onChanged: (val) {
                    vm.alarm = val ?? true;
                    vm.notifyListeners();
                  },
                  title: const Text('30분 전 알림'),
                ),
                CheckboxListTile(
                  value: vm.shareWithFriends,
                  onChanged: (val) {
                    vm.shareWithFriends = val ?? true;
                    vm.notifyListeners();
                  },
                  title: const Text('친구들과 공유'),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('취소'),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        await vm.saveSchedule();
                        Navigator.pop(context, true); // 저장 완료 후 결과 반환
                      },
                      child: const Text('저장'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
