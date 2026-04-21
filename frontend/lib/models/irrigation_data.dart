class IrrigationData {
  final String rain;
  final String decision;
  final String mode;
  final String soilType;
  final String amc;
  final double rawRainMm;
  final double et0Mm;
  final double effectiveRainMm;
  final double cropWaterLossMm;
  final double irrigationMm;
  final String weatherSource;

  IrrigationData({
    required this.rain,
    required this.decision,
    required this.mode,
    required this.soilType,
    required this.amc,
    required this.rawRainMm,
    required this.et0Mm,
    required this.effectiveRainMm,
    required this.cropWaterLossMm,
    required this.irrigationMm,
    required this.weatherSource,
  });

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? fallback;
  }

  factory IrrigationData.fromJson(Map<String, dynamic> json) {
    final rawRainMm = _asDouble(json["raw_rain_mm"], fallback: _asDouble(json["rain"]));
    return IrrigationData(
      rain: rawRainMm.toStringAsFixed(2),
      decision: json["decision"]?.toString() ?? "Bilgi yok",
      mode: json["mode"]?.toString() ?? "Bilgi yok",
      soilType: json["soil_type"]?.toString() ?? "Bilgi yok",
      amc: json["amc"]?.toString() ?? "Bilgi yok",
      rawRainMm: rawRainMm,
      et0Mm: _asDouble(json["et0_mm"]),
      effectiveRainMm: _asDouble(json["effective_rain_mm"]),
      cropWaterLossMm: _asDouble(json["crop_water_loss_mm"]),
      irrigationMm: _asDouble(json["irrigation_mm"]),
      weatherSource: json["weather_source"]?.toString() ?? "unknown",
    );
  }
}
