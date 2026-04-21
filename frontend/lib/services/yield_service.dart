import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';
import '../models/yield_prediction.dart';

class YieldService {
  static Future<Either<String, YieldPrediction>> predictByCountry({
    required String commodity,
    required String country,
  }) async {
    return _predict({
      "commodity": commodity,
      "country": country,
    });
  }

  static Future<Either<String, YieldPrediction>> predictByCoordinates({
    required String commodity,
    required double lat,
    required double lng,
  }) async {
    return _predict({
      "commodity": commodity,
      "lat": lat,
      "lng": lng,
    });
  }

  static Future<Either<String, YieldPrediction>> _predict(Map<String, dynamic> payload) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/yield"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return Right(YieldPrediction.fromJson(json));
      }

      try {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        final detail = body['detail']?.toString() ?? body['message']?.toString();
        return Left(detail != null && detail.isNotEmpty
            ? detail
            : "Sunucu hatası: ${response.statusCode}");
      } catch (_) {
        return Left("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      return Left("Bağlantı hatası: $e");
    }
  }
}
