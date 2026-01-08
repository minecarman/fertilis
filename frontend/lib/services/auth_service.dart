import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data['error'] ?? "Giriş başarısız"};
      }
    } catch (e) {
      return {"success": false, "message": "Bağlantı hatası: $e"};
    }
  }

  static Future<Map<String, dynamic>> register(String fullName, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/register"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "full_name": fullName,
          "email": email,
          "password": password
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 201) {
        return {"success": true, "data": data};
      } else {
        return {"success": false, "message": data['error'] ?? "Kayıt başarısız"};
      }
    } catch (e) {
      return {"success": false, "message": "Bağlantı hatası: $e"};
    }
  }
}