import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';
import '../models/irrigation_data.dart';

class IrrigationService {
  static Future<Either<String, IrrigationData>> analyzeRain(
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

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(IrrigationData.fromJson(data));
      } else {
        return Left("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      return Left("Bağlantı hatası: $e");
    }
  }
}
