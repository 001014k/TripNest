import 'package:flutter/material.dart';
import 'package:flutter_zoom_drawer/flutter_zoom_drawer.dart';
import 'package:fluttertrip/views/calender/schedule_editor_view.dart';
import 'package:fluttertrip/views/calender/daily_schedule_view.dart';
import 'package:fluttertrip/views/widgets/zoom_drawer_container.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../../viewmodels/calender/calender_main_viewmodel.dart';

class CalendarMainView extends StatefulWidget {
  const CalendarMainView({super.key});

  @override
  State<CalendarMainView> createState() => _CalendarMainViewState();
}

class _CalendarMainViewState extends State<CalendarMainView> {
  int selectedIndex = 4;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final viewModel = Provider.of<CalendarViewModel>(context, listen: false);
    viewModel.loadMonth(viewModel.focusedDay);
  }

  @override
  Widget build(BuildContext context) {
    return ZoomDrawerContainer(
      selectedIndex: selectedIndex,
      onItemSelected: (index) {
        setState(() => selectedIndex = index);
      },
      mainScreenBuilder: (context) => _buildMainScreen(context),
    );
  }

  Widget _buildMainScreen(BuildContext context) {
    return Consumer<CalendarViewModel>(
      builder: (context, vm, _) {
        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  DateFormat('yyyy년 M월').format(vm.focusedDay),
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
                icon: const Icon(Icons.menu),
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
                focusedDay: vm.focusedDay,
                selectedDayPredicate: (day) => isSameDay(day, vm.selectedDay),
                onDaySelected: (selectedDay, focusedDay) {
                  vm.onDaySelected(selectedDay, focusedDay);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DailyScheduleView(date: selectedDay),
                    ),
                  );
                },
                onPageChanged: (focusedDay) {
                  vm.loadMonth(focusedDay);
                },
                eventLoader: vm.eventsForDay,
                calendarStyle: const CalendarStyle(
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
                        final color = Colors.blue; // 혹은 e.category에 따라 색상
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
              if (vm.selectedDay != null)
                Expanded(
                  child: ListView(
                    children: vm.selectedEvents.map((event) {
                      return ListTile(
                        leading: const Icon(Icons.circle, size: 12, color: Colors.blue),
                        title: Text(event.title),
                        subtitle: Text(
                          '${DateFormat.Hm().format(event.startTime)} - ${DateFormat.Hm().format(event.endTime)}',
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
