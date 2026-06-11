import 'crop_catalog.dart';

class Recommendation {
  final String rawName;
  final String displayName;
  final int rank;
  final double recommendationRate;
  final String description;
  final String plantingCalendar;

  Recommendation({
    required this.rawName,
    required this.displayName,
    required this.rank,
    required this.recommendationRate,
    required this.description,
    required this.plantingCalendar,
  });

  static String translate(String name) {
    return translateCropName(name);
  }

  static List<Recommendation> fromJsonList(List<dynamic> jsonList) {
    return jsonList.asMap().entries.map((entry) {
      int idx = entry.key;
      var item = entry.value;

      String name = '';
      double recommendationRate = 92 - (idx * 12);
      if (recommendationRate < 40) recommendationRate = 40;
      String recommendationDesc = 'Öneri oranı hesaplanıyor';
      String plantingInfo = 'Ekim tablosu bilgisi bulunamadı.';

      if (item is String) {
        name = item;
      } else if (item is Map) {
        name = item['name'] ?? '';
        final rawRate = item['recommendation_rate'];
        if (rawRate != null) {
          final parsedRate = double.tryParse(rawRate.toString());
          if (parsedRate != null) {
            recommendationRate = parsedRate;
          }
        }
        if (item['planting_calendar'] != null) {
          plantingInfo = item['planting_calendar'];
        }
      }

      recommendationDesc = '%${recommendationRate.toStringAsFixed(0)} Öneri Oranı';

      return Recommendation(
        rawName: name,
        displayName: translateCropName(name),
        rank: idx + 1,
        recommendationRate: recommendationRate,
        description: recommendationDesc,
        plantingCalendar: plantingInfo,
      );
    }).toList();
  }
}
