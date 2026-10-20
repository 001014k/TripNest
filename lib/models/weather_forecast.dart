class ForecastDay {
  const ForecastDay(
      {required this.date,
      this.condition,
      this.low,
      this.high,
      this.rainProbability,
      this.source});
  final DateTime date;
  final String? condition, source;
  final double? low, high;
  final int? rainProbability;
}

class WeeklyWeather {
  const WeeklyWeather(
      {required this.days, required this.midRegion, this.notice});
  final List<ForecastDay> days;
  final String midRegion;
  final String? notice;
}
