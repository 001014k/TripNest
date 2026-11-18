import 'package:flutter/foundation.dart';
import 'dart:ui' show Locale;
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../../services/weather/weather_service.dart';
import '../../models/weather/weather_forecast.dart';

/// 앱 범위의 날씨 상태는 홈 화면이 제거되었다가 다시 생성되어도 유지됩니다.
class HomeWeatherViewModel extends ChangeNotifier {
  HomeWeatherViewModel({WeatherService? service})
      : _service = service ?? WeatherService();
  final WeatherService _service;
  bool _disposed = false;
  bool _initialized = false;
  double _lat = 37.5665, _lon = 126.978;
  String _region = '위치 확인 중';
  bool _automaticRegion = true;
  bool _hasRegion = false;
  WeatherData? _weather;
  String? _error;
  bool _loading = false;
  int _requestId = 0;

  String get region => _region;
  WeatherData? get weather => _weather;
  String? get error => _error;
  bool get loading => _loading;

  Future<void> initialize() async {
    if (_initialized) {
      await reload();
      return;
    }
    _initialized = true;
    await useCurrentLocation();
  }

  Future<void> reload({bool force = false}) => _automaticRegion
      ? useCurrentLocation(force: force)
      : _reload(force: force);

  Future<void> selectRegion(
      String name, double latitude, double longitude) async {
    _initialized = true;
    _automaticRegion = false;
    _hasRegion = true;
    _requestId++;
    _loading = false;
    _lat = latitude;
    _lon = longitude;
    _region = name;
    _weather = _service.cachedWeather(latitude, longitude);
    await _reload();
  }

  Future<WeeklyWeather> loadWeek(bool force) {
    if (!_hasRegion) throw WeatherException('현재 위치를 확인하거나 지역을 선택해주세요.');
    return _service.loadWeek(_lat, _lon, force: force);
  }

  Future<void> useCurrentLocation({bool force = false}) async {
    if (_disposed || _loading) return;
    _automaticRegion = true;
    final request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('위치 서비스를 켜거나 지역을 직접 선택해주세요.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        throw StateError('위치 접근을 허용하거나 지역을 직접 선택해주세요.');
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.low, timeLimit: Duration(seconds: 7)));
      final grid = WeatherService.grid(position.latitude, position.longitude);
      if (grid.$1 < 1 || grid.$1 > 149 || grid.$2 < 1 || grid.$2 > 253) {
        throw StateError('국내 지역을 선택해주세요.');
      }
      String name = '현재 위치';
      try {
        final geocoder = Geocoding();
        final places = await geocoder
            .placemarkFromCoordinates(position.latitude, position.longitude,
                locale: const Locale('ko', 'KR'))
            .timeout(const Duration(seconds: 5));
        if (places.isNotEmpty) {
          final place = places.first;
          name = [
            place.locality,
            place.administrativeArea,
            place.subAdministrativeArea
          ].whereType<String>().firstWhere((value) => value.trim().isNotEmpty,
              orElse: () => '현재 위치');
        }
      } catch (_) {/* 날씨 조회에는 계속 실제 좌표를 사용합니다. */}
      if (_disposed || request != _requestId) return;
      _lat = position.latitude;
      _lon = position.longitude;
      _region = name;
      _hasRegion = true;
      _weather = _service.cachedWeather(_lat, _lon);
      _loading = false;
      await _reload(force: force);
    } catch (error) {
      if (_disposed || request != _requestId) return;
      _loading = false;
      _error = error is StateError
          ? error.message.toString()
          : '위치를 확인하지 못했어요. 다시 시도하거나 지역을 선택해주세요.';
      if (!_hasRegion) _region = '지역 선택';
      notifyListeners();
    }
  }

  Future<void> _reload({bool force = false}) async {
    if (_disposed || _loading) return;
    final request = ++_requestId;
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final data = await _service.load(_lat, _lon, force: force);
      if (_disposed || request != _requestId) return;
      _weather = data;
      notifyListeners();
    } catch (error) {
      if (_disposed || request != _requestId) return;
      _error = error is WeatherException ? error.message : '날씨를 불러오지 못했어요.';
      notifyListeners();
    } finally {
      if (!_disposed && request == _requestId) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _requestId++;
    _service.dispose();
    super.dispose();
  }
}
