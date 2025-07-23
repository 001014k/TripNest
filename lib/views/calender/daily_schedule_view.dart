import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../../viewmodels/calender/daily_schedule_viewmodel.dart';

class DailyScheduleView extends StatelessWidget {
  final DateTime date;

  const DailyScheduleView({super.key, required this.date});

  String _formatTimeRange(DateTime start, DateTime end) {
    final formatter = DateFormat.Hm();
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
              return const Center(child: Text('일정이 없습니다.'));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: schedules.length,
              itemBuilder: (_, index) {
                final event = schedules[index];

                return Slidable(
                  key: ValueKey(event.id),
                  endActionPane: ActionPane(
                    motion: const ScrollMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (_) {
                          Navigator.pushNamed(
                            context,
                            '/schedule_editor',
                            arguments: event.toJson(),
                          );
                        },
                        backgroundColor: Colors.blue,
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
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      leading: Icon(Icons.schedule, color: event.color),
                      title: Text(event.title),
                      subtitle: Text(_formatTimeRange(event.startTime, event.endTime)),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (event.latitude != null)
                            const Icon(Icons.map),
                          if (event.collaboratorIds?.isNotEmpty ?? false)
                            const Icon(Icons.group, size: 20),
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
              '/map_daily_schedule',
              arguments: date,
            );
          },
        ),
      ),
    );
  }
}
