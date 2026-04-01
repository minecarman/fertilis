class Crop {
  final String rawName;
  final String displayName;
  final int rank;
  final String description;

  Crop({
    required this.rawName,
    required this.displayName,
    required this.rank,
    this.description = 'Algoritmik eşleşme oranı yüksek',
  });

  static String translate(String name) {
    const translations = {
      'wheat': 'Buğday',
      'barley': 'Arpa',
      'sugarbeet': 'Şeker Pancarı',
      'sunflower': 'Ayçiçeği',
      'cotton': 'Pamuk',
      'maize': 'Mısır',
      'lentil': 'Mercimek',
      'chickpea': 'Nohut',
      'tomato': 'Domates',
      'potato': 'Patates',
      'onion': 'Soğan',
      'tea': 'Çay',
      'hazelnut': 'Fındık',
      'olive': 'Zeytin',
      'grapes': 'Üzüm',
    };
    return translations[name] ?? name.toUpperCase();
  }

  // string to crop object factory method
  static List<Crop> fromStringList(List<dynamic> stringList) {
    List<Crop> crops = [];
    for (int i = 0; i < stringList.length; i++) {
      String name = stringList[i].toString();
      crops.add(Crop(
        rawName: name,
        displayName: translate(name),
        rank: i + 1,
      ));
    }
    return crops;
  }
}