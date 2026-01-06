import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class WeatherService {
  static Future<Map<String, dynamic>?> getWeather(double lat, double lon) async {
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
        return jsonDecode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("Hava durumu hatası: $e");
      return null;
    }
  }
}