import 'home_skeleton.dart';
import '../common/app_overlays.dart';
import '../weather/weather_forecast_sheet.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/home/home_weather_viewmodel.dart';
import '../../services/weather/weather_service.dart';

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
    // 프로바이더 트리 구성이 끝난 뒤 변경 알림을 보냅니다.
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
          AppSheetOption(
            title: '현재 위치로 설정',
            icon: Icons.my_location,
            onTap: () => Navigator.pop(sheet, ('현재 위치', 0.0, 0.0)),
          ),
          for (final city in cities)
            AppSheetOption(
              title: city.$1,
              icon: Icons.location_on_outlined,
              selected: _model.region == city.$1,
              onTap: () => Navigator.pop(sheet, city),
            )
        ],
      ),
    );
    if (city == null || !mounted) return;
    if (city.$1 == '현재 위치') {
      await _model.useCurrentLocation();
    } else {
      await _model.selectRegion(city.$1, city.$2, city.$3);
    }
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
    if (loading && data == null) {
      // 일반 화면 높이에 맞춥니다: 날씨 행 48px + 하단 영역 44px + 여백.
      return HomeSkeleton(
        height: 112 * MediaQuery.textScalerOf(context).scale(1).clamp(1, 2),
      );
    }
    final icon = data == null
        ? Icons.cloud_outlined
        : data.precipitation == 3 || data.precipitation == 7
            ? Icons.ac_unit
            : data.precipitation != 0
                ? Icons.umbrella_outlined
                : data.sky == 1
                    ? Icons.wb_sunny_rounded
                    : Icons.cloud_rounded;
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(icon, size: 27),
                const SizedBox(width: 8),
                if (data != null)
                  Text('${data.temperature.round()}°',
                      style: const TextStyle(
                          fontSize: 29, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                Expanded(
                    child: Text(
                        data == null
                            ? '날씨 정보 없음'
                            : '${data.condition}\n최고 ${data.high?.round() ?? '–'}° · 최저 ${data.low?.round() ?? '–'}°',
                        style: const TextStyle(fontSize: 13, height: 1.5))),
                const SizedBox(width: 8),
                Expanded(
                    child: Align(
                        alignment: Alignment.centerRight,
                        child: OutlinedButton.icon(
                          onPressed: onRegion,
                          icon:
                              const Icon(Icons.location_on_outlined, size: 16),
                          label: Row(mainAxisSize: MainAxisSize.min, children: [
                            Flexible(
                                child: Text(region,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const Icon(Icons.keyboard_arrow_down, size: 16),
                          ]),
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(0, 48),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                        ))),
              ]),
              const SizedBox(height: 8),
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
