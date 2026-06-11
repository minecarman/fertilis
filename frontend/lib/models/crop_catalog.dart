const Map<String, String> cropTranslations = {
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
  'pigeonpeas': 'Bezelye',
  'pomegranate': 'Nar',
  'potato': 'Patates',
  'rice': 'Pirinç',
  'sugarbeet': 'Şeker Pancarı',
  'sugarcane': 'Şeker Kamışı',
  'sunflower': 'Ayçiçeği',
  'tea': 'Çay',
  'tomato': 'Domates',
  'watermelon': 'Karpuz',
  'wheat': 'Buğday',
};

List<String> getPossibleCropNames() => cropTranslations.keys.toList(growable: false);

List<MapEntry<String, String>> getPossibleCropChoices() => cropTranslations.entries.toList(growable: false);

String? normalizeCropName(String? name) {
  if (name == null) return null;

  final key = name.toLowerCase().trim();
  if (key.isEmpty) return null;

  for (final entry in cropTranslations.entries) {
    if (entry.key == key || entry.value.toLowerCase() == key) {
      return entry.key;
    }
  }

  return null;
}

String translateCropName(String name) {
  final key = name.toLowerCase().trim();
  if (cropTranslations.containsKey(key)) return cropTranslations[key]!;
  if (name.isEmpty) return name;
  return name[0].toUpperCase() + name.substring(1).toLowerCase();
}