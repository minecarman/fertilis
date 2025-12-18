import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';

class ChatService {
  static Future<String> sendMessage(String message) async {
    final response = await http.post(
      Uri.parse("${ApiConfig.baseUrl}/chat"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"message": message}),
    );

    final data = jsonDecode(response.body);
    return data["reply"];
  }
}
