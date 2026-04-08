class Recommendation {
  final String rawName;
  final String displayName;
  final int rank;
  final String description;
  final String plantingCalendar;

  Recommendation({
    required this.rawName,
    required this.displayName,
    required this.rank,
    required this.description,
    required this.plantingCalendar,
  });

  static String translate(String name) {
    const translations = {
      'almond': 'Badem',
      'apple': 'Elma',
      'banana': 'Muz',
      'barley': 'Arpa',
      'blackgram': 'Kara Maş Fasulyesi',
      'chickpea': 'Nohut',
      'citrus': 'Narenciye',
      'coconut': 'Hindistan Cevizi',
      'coffee': 'Kahve',
      'cotton': 'Pamuk',
      'fig': 'İncir',
      'grape': 'Üzüm',
      'grapes': 'Üzüm',
      'hazelnut': 'Fındık',
      'jute': 'Jüt (Lif)',
      'kidneybeans': 'Barbunya',
      'lentil': 'Mercimek',
      'maize': 'Mısır',
      'mango': 'Mango',
      'mothbeans': 'Güve Fasulyesi',
      'mungbean': 'Maş Fasulyesi',
      'muskmelon': 'Kavun',
      'olive': 'Zeytin',
      'onion': 'Soğan',
      'orange': 'Portakal',
      'papaya': 'Papaya',
      'pigeonpeas': 'Güvercin Bezelyesi',
      'pomegranate': 'Nar',
      'potato': 'Patates',
      'rice': 'Çeltik (Pirinç)',
      'sugarbeet': 'Şeker Pancarı',
      'sugarcane': 'Şeker Kamışı',
      'sunflower': 'Ayçiçeği',
      'tea': 'Çay',
      'tomato': 'Domates',
      'watermelon': 'Karpuz',
      'wheat': 'Buğday',
    };

    String key = name.toLowerCase().trim();
    if (translations.containsKey(key)) return translations[key]!;
    return name[0].toUpperCase() + name.substring(1).toLowerCase();
  }

  static List<Recommendation> fromJsonList(List<dynamic> jsonList) {
    return jsonList.asMap().entries.map((entry) {
      int idx = entry.key;
      var item = entry.value;

      String name = '';
      String confidenceDesc = 'Algoritmik eşleşme oranı yüksek';
      String plantingInfo = 'Ekim tablosu bilgisi bulunamadı.';

      if (item is String) {
        name = item;
      } else if (item is Map) {
        name = item['name'] ?? '';
        if (item['confidence'] != null) {
          confidenceDesc = '%${item['confidence']} AI Uyum Oranı';
        }
        if (item['planting_calendar'] != null) {
          plantingInfo = item['planting_calendar'];
        }
      }

      return Recommendation(
        rawName: name,
        displayName: translate(name),
        rank: idx + 1,
        description: confidenceDesc,
        plantingCalendar: plantingInfo,
      );
    }).toList();
  }
}
