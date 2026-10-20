import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import '../services/weather_service.dart';
import '../models/weather_forecast.dart';

/// App-scoped weather state survives home route removal and recreation.
class HomeWeatherViewModel extends ChangeNotifier {
  HomeWeatherViewModel({WeatherService? service})
      : _service = service ?? WeatherService();
  final WeatherService _service;
  bool _disposed = false;
  bool _initialized = false;
  double _lat = 37.5665, _lon = 126.978;
  String _region = '서울 · 기본 지역';
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
    await _useLocation();
  }

  Future<void> reload({bool force = false}) => _reload(force: force);

  Future<void> selectRegion(
      String name, double latitude, double longitude) async {
    _initialized = true;
    _requestId++;
    _loading = false;
    _lat = latitude;
    _lon = longitude;
    _region = name;
    _weather = _service.cachedWeather(latitude, longitude);
    await _reload();
  }

  Future<WeeklyWeather> loadWeek(bool force) =>
      _service.loadWeek(_lat, _lon, force: force);

  Future<void> _useLocation() async {
    final request = ++_requestId;
    _loading = true;
    notifyListeners();
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        final position = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
                accuracy: LocationAccuracy.low,
                timeLimit: Duration(seconds: 7)));
        if (_disposed || request != _requestId) return;
        final grid = WeatherService.grid(position.latitude, position.longitude);
        if (grid.$1 >= 1 && grid.$1 <= 149 && grid.$2 >= 1 && grid.$2 <= 253) {
          _lat = position.latitude;
          _lon = position.longitude;
          _region = '현재 위치';
        }
      }
    } catch (_) {/* Use the explicitly labelled default region. */}
    if (!_disposed && request == _requestId) {
      _loading = false;
      await _reload();
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
