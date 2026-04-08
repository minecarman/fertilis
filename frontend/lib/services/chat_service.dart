import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';

class ChatService {
  static Future<Either<String, String>> sendMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"message": message}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Right(data["reply"]?.toString() ?? "Cevap yok");
      } else {
        return Left("Sunucu hatası: ${response.statusCode}");
      }
    } catch (e) {
      return Left("Bağlantı hatası: $e");
    }
  }
}
