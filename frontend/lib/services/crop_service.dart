import '../models/crop.dart';

class CropService {
  // DUMMY LAN BU
  static Future<Crop> getRecommendation() async {
    await Future.delayed(const Duration(seconds: 1));

    return Crop(
      name: "Patates",
      reason: "Başka şey yetişmiyo",
    );
  }
}
