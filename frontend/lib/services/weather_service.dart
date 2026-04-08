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
        Uri.parse("${ApiConfig.baseUrl}/api/v1/weather"),
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

  static Future<Either<String, List<Weather>>> getForecast(double lat, double lon) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/weather/forecast"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lat": lat,
          "lon": lon,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final city = data['city'];
        final List<dynamic> forecastList = data['forecast'];
        final List<Weather> weathers = forecastList.map((item) {
          return Weather(
            temp: item['temp'].toInt(),
            description: item['description'],
            humidity: item['humidity'].toInt(),
            wind: item['wind'].toDouble(),
            icon: item['icon'],
            city: city,
            date: item['date'], // Tarih verisi Weather modelinde eklenebilir.
          );
        }).toList();
        return Right(weathers);
      } else {
        return Left("Tahmin servisine ulaşılamadı. Durum: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("Hava durumu tahmini hatası: $e");
      return Left("Bağlantı Hatası: $e");
    }
  }
}