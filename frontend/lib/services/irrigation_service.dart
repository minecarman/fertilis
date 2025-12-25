import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class IrrigationService {
  static Future<Map<String, dynamic>> analyzeRain(
      double lat, double lon) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/irrigation"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": lat,
          "lon": lon,
        }),
      );

      final data = jsonDecode(response.body);

      return {  // veri null gelirse null yerine default gelecekler:
        "rain": data["rain"] ?? "Bilgi yok",
        "decision": data["decision"] ?? "Bilgi yok",
      };
    } catch (e) {
      return {    // internette sorun olursa
        "rain": "N/A",
        "decision": "Bağlantı hatası",
      };
    }
  }
}
