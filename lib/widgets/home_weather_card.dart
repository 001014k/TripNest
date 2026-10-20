import 'app_overlays.dart';
import 'weather_forecast_sheet.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/home_weather_viewmodel.dart';
import '../services/weather_service.dart';

class HomeWeatherCard extends StatefulWidget {
  const HomeWeatherCard({super.key});
  @override
  State<HomeWeatherCard> createState() => _HomeWeatherCardState();
}

class _HomeWeatherCardState extends State<HomeWeatherCard>
    with WidgetsBindingObserver {
  late final HomeWeatherViewModel _model;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _model = context.read<HomeWeatherViewModel>();
    WidgetsBinding.instance.addObserver(this);
    // Defer notifications until the provider tree has finished building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _model.initialize();
    });
    _timer = Timer.periodic(const Duration(minutes: 20), (_) {
      if (WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed) {
        _model.reload();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _model.reload();
  }

  Future<void> _pickRegion() async {
    const cities = [
      ('서울', 37.5665, 126.978),
      ('부산', 35.1796, 129.0756),
      ('인천', 37.4563, 126.7052),
      ('대전', 36.3504, 127.3845),
      ('대구', 35.8714, 128.6014),
      ('광주', 35.1595, 126.8526),
      ('강릉', 37.7519, 128.8761),
      ('제주', 33.4996, 126.5312)
    ];
    final city = await showAppSheet<(String, double, double)>(
      context: context,
      builder: (sheet) => AppSheet(
        title: '날씨 지역 선택',
        subtitle: '날씨를 확인할 지역을 선택해주세요.',
        children: [
          for (final city in cities)
            AppSheetOption(
              title: city.$1,
              icon: Icons.location_on_outlined,
              selected: _model.region == city.$1 ||
                  (_model.region == '서울 · 기본 지역' && city.$1 == '서울'),
              onTap: () => Navigator.pop(sheet, city),
            )
        ],
      ),
    );
    if (city == null || !mounted) return;
    await _model.selectRegion(city.$1, city.$2, city.$3);
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _openForecast() {
    showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        backgroundColor: Colors.white,
        builder: (_) =>
            WeatherForecastSheet(region: _model.region, load: _model.loadWeek));
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: _model,
      builder: (context, _) => GestureDetector(
          onTap: _openForecast,
          child: WeatherCardContent(
              region: _model.region,
              weather: _model.weather,
              loading: _model.loading,
              error: _model.error,
              onRegion: _pickRegion,
              onForecast: _openForecast,
              onRetry: () => _model.reload(force: true))));
}

class WeatherCardContent extends StatelessWidget {
  const WeatherCardContent(
      {super.key,
      required this.region,
      required this.weather,
      required this.loading,
      required this.error,
      required this.onRegion,
      this.onForecast,
      required this.onRetry});
  final String region;
  final WeatherData? weather;
  final bool loading;
  final String? error;
  final VoidCallback onRegion, onRetry;
  final VoidCallback? onForecast;

  @override
  Widget build(BuildContext context) {
    final data = weather;
    final icon = data == null
        ? Icons.cloud_outlined
        : data.precipitation == 3 || data.precipitation == 7
            ? Icons.ac_unit
            : data.precipitation != 0
                ? Icons.umbrella_outlined
                : data.sky == 1
                    ? Icons.wb_sunny_rounded
                    : Icons.cloud_rounded;
    return Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        decoration: BoxDecoration(
            color: const Color(0xFFF3F8FC),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDCE7F2))),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      InkWell(
                          onTap: onRegion,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Row(children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 20),
                                const SizedBox(width: 6),
                                Flexible(
                                    child: Text(region,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700))),
                                const Icon(Icons.keyboard_arrow_down, size: 16),
                              ]))),
                      if (data != null)
                        Text(
                            '${data.condition} · 최고 ${data.high?.round().toString() ?? '–'}° 최저 ${data.low?.round().toString() ?? '–'}°',
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF7D8390))),
                      if (data == null)
                        Text(loading ? '날씨를 불러오는 중이에요' : '날씨 정보 없음',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF7D8390))),
                    ])),
                const SizedBox(width: 8),
                if (loading && data == null)
                  const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2))
                else if (data != null)
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(icon,
                        size: 32,
                        color: data.sky == 1 && data.precipitation == 0
                            ? const Color(0xFFF5BC32)
                            : const Color(0xFF87ACC7)),
                    const SizedBox(width: 6),
                    Text('${data.temperature.round()}°',
                        style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1)),
                  ]),
              ]),
              const Divider(height: 18, color: Color(0xFFDCE5EF)),
              if (error != null)
                Row(children: [
                  Expanded(
                      child: Text(error!,
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF767E8D)))),
                  TextButton(
                      onPressed: loading ? null : onRetry,
                      child: const Text('재시도')),
                ]),
              Row(key: const ValueKey('weather-footer'), children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (error == null)
                        Text(data?.advice ?? '잠시만 기다려주세요.',
                            style: const TextStyle(
                                fontSize: 12, color: Color(0xFF767E8D))),
                      if (data != null) ...[
                        if (error == null) const SizedBox(height: 4),
                        Text(
                          '기상청 · ${data.observedAt.month}/${data.observedAt.day} ${data.observedAt.hour.toString().padLeft(2, '0')}:00 관측',
                          style: const TextStyle(
                              fontSize: 9, color: Color(0xFF8C95A1)),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onForecast != null)
                  TextButton(
                    onPressed: onForecast,
                    style: TextButton.styleFrom(
                      minimumSize: const Size(44, 44),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      foregroundColor: const Color(0xFF60788C),
                      textStyle: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('주간 예보'),
                        SizedBox(width: 2),
                        Icon(Icons.chevron_right_rounded, size: 16),
                      ],
                    ),
                  ),
              ]),
            ]));
  }
}
