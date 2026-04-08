import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';
import '../models/weather.dart';

class WeatherService {
  static Future<Either<String, Weather>> getWeather(double lat, double lon) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/weather"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": lat,
          "lon": lon,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(Weather.fromJson(data));
      } else {
        return Left("Hava durumu servisine ulaşılamadı. Durum: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Hava durumu hatası: $e");
      return Left("Bağlantı Hatası: $e");
    }
  }
}