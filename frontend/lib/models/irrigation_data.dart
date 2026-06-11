class IrrigationData {
  final String rain;
  final String decision;
  final String mode;
  final String soilType;
  final String crop;
  final String amc;
  final double rawRainMm;
  final double et0Mm;
  final double effectiveRainMm;
  final double cropWaterLossMm;
  final double baseIrrigationMm;
  final double irrigationMm;
  final int recommendedIrrigationDays;
  final int lastIrrigatedDays;
  final double timingFactor;
  final String weatherSource;
  final String scheduleStatus;

  IrrigationData({
    required this.rain,
    required this.decision,
    required this.mode,
    required this.soilType,
    required this.crop,
    required this.amc,
    required this.rawRainMm,
    required this.et0Mm,
    required this.effectiveRainMm,
    required this.cropWaterLossMm,
    required this.baseIrrigationMm,
    required this.irrigationMm,
    required this.recommendedIrrigationDays,
    required this.lastIrrigatedDays,
    required this.timingFactor,
    required this.weatherSource,
    required this.scheduleStatus,
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
      crop: json["crop"]?.toString() ?? "Bilgi yok",
      amc: json["amc"]?.toString() ?? "Bilgi yok",
      rawRainMm: rawRainMm,
      et0Mm: _asDouble(json["et0_mm"]),
      effectiveRainMm: _asDouble(json["effective_rain_mm"]),
      cropWaterLossMm: _asDouble(json["crop_water_loss_mm"]),
      baseIrrigationMm: _asDouble(json["base_irrigation_mm"], fallback: _asDouble(json["irrigation_mm"])),
      irrigationMm: _asDouble(json["irrigation_mm"]),
      recommendedIrrigationDays: _asDouble(json["recommended_irrigation_days"]).round(),
      lastIrrigatedDays: _asDouble(json["last_irrigated_days"]).round(),
      timingFactor: _asDouble(json["timing_factor"], fallback: 1.0),
      weatherSource: json["weather_source"]?.toString() ?? "unknown",
      scheduleStatus: json["schedule_status"]?.toString() ?? "Bilgi yok",
    );
  }
}
