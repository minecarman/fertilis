class YieldPrediction {
  final String status;
  final String inputMode;
  final String resolvedCountry;
  final YieldPredictionDetails prediction;

  YieldPrediction({
    required this.status,
    required this.inputMode,
    required this.resolvedCountry,
    required this.prediction,
  });

  factory YieldPrediction.fromJson(Map<String, dynamic> json) {
    return YieldPrediction(
      status: json["status"]?.toString() ?? "unknown",
      inputMode: json["input_mode"]?.toString() ?? "unknown",
      resolvedCountry: json["resolved_country"]?.toString() ?? "unknown",
      prediction: YieldPredictionDetails.fromJson(
        (json["prediction"] as Map<String, dynamic>?) ?? {},
      ),
    );
  }
}

class YieldPredictionDetails {
  final String country;
  final String commodity;
  final String latestSeason;
  final double predictedProductionMt;
  final double? currentProductionMt;
  final double? deltaMt;
  final String? trend;

  YieldPredictionDetails({
    required this.country,
    required this.commodity,
    required this.latestSeason,
    required this.predictedProductionMt,
    required this.currentProductionMt,
    required this.deltaMt,
    required this.trend,
  });

  static double _asDouble(dynamic value, {double fallback = 0.0}) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? "") ?? fallback;
  }

  static double? _asNullableDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  factory YieldPredictionDetails.fromJson(Map<String, dynamic> json) {
    return YieldPredictionDetails(
      country: json["country"]?.toString() ?? "unknown",
      commodity: json["commodity"]?.toString() ?? "unknown",
      latestSeason: json["latest_season"]?.toString() ?? "unknown",
      predictedProductionMt: _asDouble(json["predicted_production_mt"]),
      currentProductionMt: _asNullableDouble(json["current_production_mt"]),
      deltaMt: _asNullableDouble(json["delta_mt"]),
      trend: json["trend"]?.toString(),
    );
  }
}
