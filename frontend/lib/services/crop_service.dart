import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/crop.dart';
import '../core/api_config.dart';


class CropService {
  static Future<List<Crop>> getRecommendations(double lat, double lng) async {
    try {
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/recommendations'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'lat': lat,
          'lng': lng,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true) {
          return Crop.fromStringList(data['recommendations']); 
        } else {
          throw Exception(data['error'] ?? 'Bilinmeyen bir hata oluştu');
        }
      } else {
        throw Exception('Sunucu hatası: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API Bağlantı Hatası: $e');
    }
  }
}
