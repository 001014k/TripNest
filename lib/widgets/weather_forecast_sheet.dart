import 'package:flutter/material.dart';
import '../models/weather_forecast.dart';

class WeatherForecastSheet extends StatefulWidget {
  const WeatherForecastSheet(
      {super.key, required this.region, required this.load});
  final String region;
  final Future<WeeklyWeather> Function(bool force) load;
  @override
  State<WeatherForecastSheet> createState() => _WeatherForecastSheetState();
}

class _WeatherForecastSheetState extends State<WeatherForecastSheet> {
  late Future<WeeklyWeather> _forecast = widget.load(false);

  void _refresh() {
    final nextForecast = widget.load(true);
    setState(() {
      _forecast = nextForecast;
    });
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .8,
          child: Column(children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
                child: Row(children: [
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        const Text('오늘부터 다음 주까지',
                            style: TextStyle(
                                fontSize: 21, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 5),
                        Text(widget.region,
                            style: const TextStyle(
                                fontSize: 13, color: Color(0xFF85858B))),
                      ])),
                  IconButton(
                      tooltip: '새로고침',
                      onPressed: _refresh,
                      icon: const Icon(Icons.refresh)),
                  IconButton(
                      tooltip: '닫기',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close)),
                ])),
            const Divider(height: 1, color: Color(0xFFE9E9EC)),
            Expanded(
                child: FutureBuilder<WeeklyWeather>(
                    future: _forecast,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData) {
                        return Center(
                            child: TextButton(
                                onPressed: _refresh,
                                child: const Text('예보를 불러오지 못했어요 · 재시도')));
                      }
                      final forecast = snapshot.data!;
                      return ListView(
                          padding: const EdgeInsets.all(20),
                          children: [
                            const Row(children: [
                              Expanded(
                                  child: Text('날짜 / 날씨',
                                      style: TextStyle(
                                          fontSize: 12, color: Colors.grey))),
                              Text('최저 / 최고',
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey))
                            ]),
                            const SizedBox(height: 8),
                            ...forecast.days.indexed
                                .map((entry) => _day(entry.$2, entry.$1 == 0)),
                            const SizedBox(height: 12),
                            if (forecast.notice != null)
                              Text(forecast.notice!,
                                  style: const TextStyle(
                                      fontSize: 12, color: Color(0xFF85858B))),
                            const SizedBox(height: 8),
                            Text(
                                '기상청 제공 · 중기예보는 ${forecast.midRegion} 대표 지역 기준입니다.\n강수확률은 하루 중 가장 높은 값이며, 예보는 발표에 따라 달라질 수 있어요.',
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF85858B),
                                    height: 1.5)),
                          ]);
                    })),
          ])));

  Widget _day(ForecastDay day, bool today) {
    final condition = day.condition;
    final icon = condition == null
        ? Icons.cloud_off_outlined
        : condition.contains('눈')
            ? Icons.ac_unit
            : condition.contains('비')
                ? Icons.umbrella_outlined
                : condition == '맑음'
                    ? Icons.wb_sunny_outlined
                    : Icons.cloud_outlined;
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: Color(0xFFEFEFF1)))),
        child: Row(children: [
          SizedBox(
              width: 57,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        today
                            ? '오늘'
                            : [
                                '월',
                                '화',
                                '수',
                                '목',
                                '금',
                                '토',
                                '일'
                              ][day.date.weekday - 1],
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: day.date.weekday == 7
                                ? const Color(0xFFD46B76)
                                : day.date.weekday == 6
                                    ? const Color(0xFF5DAFD0)
                                    : const Color(0xFF222222))),
                    const SizedBox(height: 4),
                    Text('${day.date.month}/${day.date.day}',
                        style:
                            const TextStyle(fontSize: 11, color: Colors.grey)),
                  ])),
          Icon(icon,
              size: 24,
              color: condition == '맑음'
                  ? const Color(0xFFF5BC32)
                  : const Color(0xFF87ACC7)),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(condition ?? '예보 미제공',
                    style: const TextStyle(fontSize: 12)),
                if (day.rainProbability != null)
                  Text('강수 ${day.rainProbability}%',
                      style: const TextStyle(fontSize: 10, color: Colors.grey)),
              ])),
          const SizedBox(width: 8),
          Text('${day.low?.round().toString() ?? '–'}°',
              style: const TextStyle(color: Color(0xFF5DAFD0), fontSize: 14)),
          const Text(' / ', style: TextStyle(color: Colors.grey)),
          Text('${day.high?.round().toString() ?? '–'}°',
              style:
                  const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ]));
  }
}
