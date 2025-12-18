import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ChatService {
  static Future<String> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["reply"] ?? "Cevap yok";
      } else {
        return "Server error (${response.statusCode})";
      }
    } catch (e) {
      return "Bağlantı hatası: $e";
    }
  }
}
