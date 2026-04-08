class IrrigationData {
  final String rain;
  final String decision;

  IrrigationData({required this.rain, required this.decision});

  factory IrrigationData.fromJson(Map<String, dynamic> json) {
    return IrrigationData(
      rain: json["rain"]?.toString() ?? "Bilgi yok",
      decision: json["decision"]?.toString() ?? "Bilgi yok",
    );
  }
}
