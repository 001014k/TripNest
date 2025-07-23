import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../viewmodels/calender/daily_schedule_viewmodel.dart';

class DailyScheduleView extends StatelessWidget {
  final DateTime date;

  const DailyScheduleView({super.key, required this.date});

  String _formatTimeRange(DateTime start, DateTime end) {
    final formatter = DateFormat('a h:mm', 'ko_KR');
    return '${formatter.format(start)} ~ ${formatter.format(end)}';
  }

  @override
  Widget build(BuildContext context) {
    final dayFormat = DateFormat('M월 d일 (E)', 'ko_KR');

    return ChangeNotifierProvider(
      create: (_) => DailyScheduleViewModel()..loadSchedules(date),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${dayFormat.format(date)} 일정'),
        ),
        body: Consumer<DailyScheduleViewModel>(
          builder: (context, viewModel, _) {
            if (viewModel.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final schedules = viewModel.schedules;

            if (schedules.isEmpty) {
              return const Center(
                child: Text(
                  '등록된 일정이 없습니다.',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (_, index) {
                final event = schedules[index];

                return Slidable(
                  key: ValueKey(event.id),
                  endActionPane: ActionPane(
                    motion: const DrawerMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) {
                          Navigator.pushNamed(
                            context,
                            '/schedule_editor',
                            arguments: event.toJson(),
                          );
                        },
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        icon: Icons.edit,
                        label: '수정',
                      ),
                      SlidableAction(
                        onPressed: (_) async {
                          await viewModel.delete(event.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('일정이 삭제되었습니다.')),
                          );
                        },
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        icon: Icons.delete,
                        label: '삭제',
                      ),
                    ],
                  ),
                  child: Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 3,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      leading: CircleAvatar(
                        backgroundColor: Color(event.colorValue),
                        child: const Icon(Icons.schedule, color: Colors.white),
                      ),
                      title: Text(
                        event.title,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            _formatTimeRange(event.startTime, event.endTime),
                            style: const TextStyle(color: Colors.grey),
                          ),
                          if (event.latitude != null)
                            Row(
                              children: const [
                                Icon(Icons.place, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('지도 위치 있음', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          if (event.collaboratorIds?.isNotEmpty ?? false)
                            Row(
                              children: const [
                                Icon(Icons.group, size: 14, color: Colors.grey),
                                SizedBox(width: 4),
                                Text('친구와 공유됨', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                        ],
                      ),
                      onTap: () {
                        if (event.latitude != null && event.longitude != null) {
                          Navigator.pushNamed(
                            context,
                            '/map_detail',
                            arguments: {
                              'lat': event.latitude,
                              'lng': event.longitude,
                              'title': event.title,
                            },
                          );
                        }
                      },
                    ),
                  ),
                );
              },
            );
          },
        ),
        floatingActionButton: FloatingActionButton.extended(
          icon: const Icon(Icons.map),
          label: const Text("지도로 보기"),
          onPressed: () {
            Navigator.pushNamed(
              context,
              '/mapsample',
              arguments: date,
            );
          },
        ),
      ),
    );
  }
}
