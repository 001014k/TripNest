import '../../models/weather/weather_forecast.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import '../../env.dart';

class WeatherData {
  const WeatherData(
      {required this.temperature,
      required this.precipitation,
      required this.observedAt,
      this.sky,
      this.high,
      this.low});
  final double temperature;
  final int precipitation;
  final int? sky;
  final double? high, low;
  final DateTime observedAt;
  String get condition => switch (precipitation) {
        1 || 5 => '비',
        2 || 6 => '비와 눈',
        3 || 7 => '눈',
        _ => switch (sky) { 1 => '맑음', 3 => '구름 많음', 4 => '흐림', _ => '강수 없음' },
      };
  String get advice => precipitation != 0
      ? '외출할 때 우산을 챙겨주세요.'
      : temperature >= 28
          ? '물을 챙기고 더위에 대비해주세요.'
          : temperature <= 5
              ? '따뜻한 겉옷을 챙겨주세요.'
              : '외출 전 하루의 날씨를 확인해보세요.';
}

class WeatherException implements Exception {
  const WeatherException(this.message);
  final String message;
  @override
  String toString() => message;
}

class WeatherService {
  WeatherService(
      {http.Client? client,
      String? apiKey,
      String? midApiKey,
      DateTime Function()? clock})
      : _client = client ?? http.Client(),
        _key = apiKey ?? Env.apiweather,
        _clock = clock ?? DateTime.now;
  final http.Client _client;
  final String _key;
  final DateTime Function() _clock;
  final Map<String, (DateTime, WeatherData)> _cache = {};
  WeatherData? cachedWeather(double latitude, double longitude) {
    final point = grid(latitude, longitude);
    return _cache['${point.$1},${point.$2}']?.$2;
  }

  void dispose() => _client.close();

  /// KMA's 5 km Lambert conformal grid (Seoul city hall = 60,127).
  static (int, int) grid(double latitude, double longitude) {
    const rad = math.pi / 180;
    const re = 6371.00877 / 5;
    const slat1 = 30 * rad, slat2 = 60 * rad;
    final sn = math.log(math.cos(slat1) / math.cos(slat2)) /
        math.log(math.tan(math.pi / 4 + slat2 / 2) /
            math.tan(math.pi / 4 + slat1 / 2));
    final sf =
        math.pow(math.tan(math.pi / 4 + slat1 / 2), sn) * math.cos(slat1) / sn;
    final ro = re * sf / math.pow(math.tan(math.pi / 4 + 38 * rad / 2), sn);
    final ra =
        re * sf / math.pow(math.tan(math.pi / 4 + latitude * rad / 2), sn);
    var theta = longitude * rad - 126 * rad;
    if (theta > math.pi) theta -= 2 * math.pi;
    if (theta < -math.pi) theta += 2 * math.pi;
    theta *= sn;
    return (
      (ra * math.sin(theta) + 43.5).floor(),
      (ro - ra * math.cos(theta) + 136.5).floor()
    );
  }

  static String dateKey(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
  static DateTime forecastBase(DateTime kst) {
    final available = kst.subtract(const Duration(minutes: 15));
    final hour = [23, 20, 17, 14, 11, 8, 5, 2]
        .where((h) => h <= available.hour)
        .firstOrNull;
    return hour == null
        ? DateTime.utc(available.year, available.month, available.day - 1, 23)
        : DateTime.utc(available.year, available.month, available.day, hour);
  }

  Future<WeatherData> load(double latitude, double longitude,
      {bool force = false}) async {
    final point = grid(latitude, longitude);
    if (point.$1 < 1 || point.$1 > 149 || point.$2 < 1 || point.$2 > 253) {
      throw const WeatherException('국내 지역을 선택해주세요.');
    }
    final now = _clock().toUtc();
    final kst = now.add(const Duration(hours: 9));
    final cacheKey = '${point.$1},${point.$2}';
    final cached = _cache[cacheKey];
    if (!force &&
        cached != null &&
        now.difference(cached.$1) < const Duration(minutes: 20)) {
      return cached.$2;
    }
    final observationBase = kst.subtract(const Duration(minutes: 45));
    final base = forecastBase(kst);
    final dailyBase = kst.hour >= 3
        ? DateTime.utc(kst.year, kst.month, kst.day, 2)
        : DateTime.utc(kst.year, kst.month, kst.day - 1, 23);
    final results = await Future.wait([
      _request('getUltraSrtNcst', observationBase, point),
      _optionalForecast(base, point),
      if (base != dailyBase) _optionalForecast(dailyBase, point),
    ]);
    final observed = {
      for (final item in results[0])
        item['category']: item['obsrValue'].toString()
    };
    final temp = double.tryParse(observed['T1H'] ?? '');
    if (temp == null) {
      throw const WeatherException('기온 자료가 아직 없어요. 잠시 후 다시 시도해주세요.');
    }
    final today = dateKey(kst);
    final hour = "${kst.hour.toString().padLeft(2, '0')}00";
    final skies = results[1]
        .where((e) => e['category'] == 'SKY' && e['fcstDate'] == today)
        .toList()
      ..sort((a, b) => (int.parse(a['fcstTime'].toString()) - int.parse(hour))
          .abs()
          .compareTo(
              (int.parse(b['fcstTime'].toString()) - int.parse(hour)).abs()));
    double? daily(String category) {
      for (final rows in results.skip(1)) {
        for (final row in rows) {
          if (row['fcstDate'] == today && row['category'] == category) {
            return double.tryParse(row['fcstValue'].toString());
          }
        }
      }
      return null;
    }

    final weather = WeatherData(
        temperature: temp,
        precipitation: int.tryParse(observed['PTY'] ?? '') ?? 0,
        sky: skies.isEmpty
            ? null
            : int.tryParse(skies.first['fcstValue'].toString()),
        high: daily('TMX'),
        low: daily('TMN'),
        observedAt: DateTime.utc(observationBase.year, observationBase.month,
            observationBase.day, observationBase.hour));
    _cache[cacheKey] = (now, weather);
    return weather;
  }

  final Map<String, (DateTime, WeeklyWeather)> _weeklyCache = {};

  Future<WeeklyWeather> loadWeek(double latitude, double longitude,
      {bool force = false}) async {
    final now = _clock().toUtc();
    final kst = now.add(const Duration(hours: 9));
    final today = DateTime.utc(kst.year, kst.month, kst.day);
    final point = grid(latitude, longitude);
    final cacheKey = '${point.$1},${point.$2}:${dateKey(today)}';
    final cached = _weeklyCache[cacheKey];
    if (!force &&
        cached != null &&
        now.difference(cached.$1) < const Duration(minutes: 20)) {
      return cached.$2;
    }
    // Mid-range temperature forecasts are issued for representative cities.
    const regions = [
      ('서울', 37.5665, 126.978, '11B00000', '11B10101'),
      ('인천', 37.4563, 126.7052, '11B00000', '11B20201'),
      ('부산', 35.1796, 129.0756, '11H20000', '11H20201'),
      ('대구', 35.8714, 128.6014, '11H10000', '11H10701'),
      ('대전', 36.3504, 127.3845, '11C20000', '11C20401'),
      ('광주', 35.1595, 126.8526, '11F20000', '11F20501'),
      ('강릉', 37.7519, 128.8761, '11D20000', '11D20501'),
      ('제주', 33.4996, 126.5312, '11G00000', '11G00201'),
    ];
    final sorted = [...regions]..sort((a, b) {
        double distance((String, double, double, String, String) r) =>
            math.pow(r.$2 - latitude, 2).toDouble() +
            math
                .pow((r.$3 - longitude) * math.cos(latitude * math.pi / 180), 2)
                .toDouble();
        return distance(a).compareTo(distance(b));
      });
    final region = sorted.first;
    final available = kst.subtract(const Duration(minutes: 15));
    final midBase = available.hour >= 6
        ? DateTime.utc(available.year, available.month, available.day,
            available.hour >= 18 ? 18 : 6)
        : DateTime.utc(available.year, available.month, available.day - 1, 18);
    String? notice;
    Future<Map<String, dynamic>> mid(String method, String code) async {
      try {
        return await _midRequest(method, code, midBase);
      } catch (_) {
        notice = '일부 예보를 불러오지 못했어요. 잠시 후 새로고침해주세요.';
        return {};
      }
    }

    final base = forecastBase(kst);
    final dailyBase = kst.hour >= 3
        ? DateTime.utc(kst.year, kst.month, kst.day, 2)
        : DateTime.utc(kst.year, kst.month, kst.day - 1, 23);
    final results = await Future.wait<Object>([
      _optionalForecast(base, point),
      _optionalForecast(dailyBase, point),
      mid('getMidLandFcst', region.$4),
      mid('getMidTa', region.$5),
    ]);
    final short = results[0] as List<Map<String, dynamic>>;
    final daily = results[1] as List<Map<String, dynamic>>;
    final land = results[2] as Map<String, dynamic>;
    final temperature = results[3] as Map<String, dynamic>;
    if (short.isEmpty) notice = '일부 예보를 불러오지 못했어요. 잠시 후 새로고침해주세요.';
    final days = List.generate(8, (index) {
      final date = today.add(Duration(days: index));
      final rows = short.where((e) => e['fcstDate'] == dateKey(date)).toList();
      double? number(dynamic value) => double.tryParse(value?.toString() ?? '');
      double? value(String category) {
        for (final row in [
          ...rows,
          ...daily.where((e) => e['fcstDate'] == dateKey(date))
        ]) {
          if (row['category'] == category) return number(row['fcstValue']);
        }
        return null;
      }

      if (rows.isNotEmpty) {
        final rain = rows
                .where((e) => e['category'] == 'PTY')
                .map((e) => number(e['fcstValue'])?.toInt() ?? 0)
                .where((e) => e > 0)
                .firstOrNull ??
            0;
        final skies = rows.where((e) => e['category'] == 'SKY').toList()
          ..sort((a, b) => (int.parse(a['fcstTime'].toString()) - 1200)
              .abs()
              .compareTo((int.parse(b['fcstTime'].toString()) - 1200).abs()));
        final probabilities = rows
            .where((e) => e['category'] == 'POP')
            .map((e) => number(e['fcstValue'])?.toInt())
            .whereType<int>()
            .toList();
        final sky =
            skies.isEmpty ? null : number(skies.first['fcstValue'])?.toInt();
        final condition = rain == 0 && sky == null
            ? null
            : WeatherData(
                    temperature: 0,
                    precipitation: rain,
                    sky: sky,
                    observedAt: date)
                .condition;
        return ForecastDay(
            date: date,
            condition: condition,
            low: value('TMN'),
            high: value('TMX'),
            rainProbability:
                probabilities.isEmpty ? null : probabilities.reduce(math.max),
            source: '단기예보');
      }
      final offset = date
          .difference(DateTime.utc(midBase.year, midBase.month, midBase.day))
          .inDays;
      final am = land['wf${offset}Am'] ?? land['wf$offset'];
      final pm = land['wf${offset}Pm'];
      final condition = am == null
          ? pm?.toString()
          : pm == null || pm == am
              ? am.toString()
              : '$am / $pm';
      final probabilities = [
        number(land['rnSt${offset}Am'] ?? land['rnSt$offset']),
        number(land['rnSt${offset}Pm'])
      ].whereType<double>().toList();
      return ForecastDay(
          date: date,
          condition: condition,
          low: number(temperature['taMin$offset']),
          high: number(temperature['taMax$offset']),
          rainProbability: probabilities.isEmpty
              ? null
              : probabilities.reduce(math.max).round(),
          source: '중기예보');
    });
    final result =
        WeeklyWeather(days: days, midRegion: region.$1, notice: notice);
    _weeklyCache[cacheKey] = (now, result);
    return result;
  }

  Future<Map<String, dynamic>> _midRequest(
      String method, String region, DateTime base) async {
    final key = _key.contains('%')
        ? Uri.decodeComponent(_key.trim())
        : _key.trim();
    final response = await _client
        .get(Uri.https(
            'apis.data.go.kr', '/1360000/MidFcstInfoService/$method', {
          'serviceKey': key,
          'dataType': 'JSON',
          'numOfRows': '10',
          'pageNo': '1',
          'regId': region,
          'tmFc': '${dateKey(base)}${base.hour.toString().padLeft(2, '0')}00',
        }))
        .timeout(const Duration(seconds: 15));
    if (response.statusCode != 200) throw const WeatherException('중기예보 조회 실패');
    final data = jsonDecode(utf8.decode(response.bodyBytes))['response'];
    if (data['header']['resultCode'].toString() != '00') {
      throw const WeatherException('중기예보 조회 실패');
    }
    final rows = data['body']?['items']?['item'];
    return rows is List && rows.isNotEmpty
        ? Map<String, dynamic>.from(rows.first)
        : {};
  }

  Future<List<Map<String, dynamic>>> _optionalForecast(
      DateTime base, (int, int) point) async {
    try {
      return await _request('getVilageFcst', base, point);
    } catch (_) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _request(
      String method, DateTime base, (int, int) point) async {
    if (_key.trim().isEmpty) throw const WeatherException('날씨 API 설정을 확인해주세요.');
    // Accept either the encoded or decoded service key supplied by data.go.kr.
    final key =
        _key.contains('%') ? Uri.decodeComponent(_key.trim()) : _key.trim();
    final uri = Uri.https(
        'apis.data.go.kr', '/1360000/VilageFcstInfoService_2.0/$method', {
      'serviceKey': key,
      'dataType': 'JSON',
      'pageNo': '1',
      'numOfRows': '1000',
      'base_date': dateKey(base),
      'base_time': '${base.hour.toString().padLeft(2, '0')}00',
      'nx': '${point.$1}',
      'ny': '${point.$2}',
    });
    try {
      final response =
          await _client.get(uri).timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const WeatherException('날씨 서버에 연결하지 못했어요.');
      }
      final data = jsonDecode(utf8.decode(response.bodyBytes))['response'];
      final code = data['header']['resultCode'].toString();
      if (code != '00') {
        throw WeatherException(['20', '30', '31', '32'].contains(code)
            ? '날씨 API 인증 또는 이용 승인을 확인해주세요.'
            : '기상청 자료를 불러오지 못했어요. 잠시 후 재시도해주세요.');
      }
      final items = data['body']?['items'];
      if (items is! Map || items['item'] is! List) return [];
      return (items['item'] as List).cast<Map<String, dynamic>>();
    } on WeatherException {
      rethrow;
    } catch (_) {
      throw const WeatherException('날씨를 불러오지 못했어요. 다시 시도해주세요.');
    }
  }
}
