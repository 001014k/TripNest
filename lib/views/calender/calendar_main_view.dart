import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:fluttertrip/views/calender/schedule_editor_view.dart';
import 'package:fluttertrip/views/widgets/zoom_drawer_container.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

import 'daily_schedule_view.dart';

class CalendarMainView extends StatefulWidget {
  const CalendarMainView({super.key});

  @override
  State<CalendarMainView> createState() => _CalendarMainViewState();
}

class _CalendarMainViewState extends State<CalendarMainView> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  int selectedIndex = 4; // 북마크/리스트 탭을 의미하는 인덱스

  // 예시 일정 정보 (날짜별 여행 이름)
  final Map<DateTime, List<Map<String, dynamic>>> _events = {
    DateTime.utc(2024, 8, 15): [
      {"title": "서울 여행", "color": Colors.blue},
    ],
    DateTime.utc(2024, 8, 16): [
      {"title": "서울 여행", "color": Colors.blue},
    ],
    DateTime.utc(2024, 8, 17): [
      {"title": "제주 여행", "color": Colors.green},
    ],
  };

  List<Map<String, dynamic>> _getEventsForDay(DateTime day) {
    final key = DateTime.utc(day.year, day.month, day.day);
    return _events[key] ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerContainer(
      selectedIndex: selectedIndex,
      onItemSelected: (index) {
        setState(() {
          selectedIndex = index;
        });
      },
      mainScreenBuilder: (context) => _buildMainScreen(context),
    );
  }

  @override
  Widget _buildMainScreen(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateFormat('yyyy년 M월').format(_focusedDay),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Text(
              '서울 여행',
              style: TextStyle(fontSize: 14),
            ),
          ],
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () {
              ZoomDrawer.of(context)?.toggle();
            },
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ScheduleEditorView(),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          TableCalendar(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });

              final events = _getEventsForDay(selectedDay);
              // 이동
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DailyScheduleView(
                    date: selectedDay,
                  ),
                ),
              );
            },
            onPageChanged: (focusedDay) {
              setState(() => _focusedDay = focusedDay);
            },
            eventLoader: _getEventsForDay,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.redAccent,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              markerDecoration: BoxDecoration(
                shape: BoxShape.circle,
              ),
              markersAlignment: Alignment.bottomCenter,
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) {
                if (events.isEmpty) return const SizedBox();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: events.map((e) {
                    final event = e as Map<String, dynamic>;
                    final color = event['color'] as Color? ?? Colors.grey;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1.0),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            headerVisible: false,
            daysOfWeekHeight: 24,
          ),
          const Divider(),
          if (_selectedDay != null)
            Expanded(
              child: ListView(
                children: _getEventsForDay(_selectedDay!).map((event) {
                  return ListTile(
                    leading: Icon(Icons.circle, color: event['color'], size: 12),
                    title: Text(event['title']),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
