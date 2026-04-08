import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';
import '../models/user.dart';

class AuthService {
  static Future<Either<String, User>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/auth/login"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"email": email, "password": password}),
      );

      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return Right(User.fromJson(data['user'] ?? {}));
      } else {
        return Left(data['error'] ?? "Giriş başarısız");
      }
    } catch (e) {
      return Left("Bağlantı hatası: $e");
    }
  }

  static Future<Either<String, User>> register(String fullName, String email, String password) async {
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
        return Right(User.fromJson(data['user'] ?? {
          'email': email,
          'full_name': fullName,
        }));
      } else {
        return Left(data['error'] ?? "Kayıt başarısız");
      }
    } catch (e) {
      return Left("Bağlantı hatası: $e");
    }
  }

  static Future<Either<String, User>> updateProfile(String oldEmail, String newEmail, String fullName) async {
    try {
      final response = await http.put(
        Uri.parse("${ApiConfig.baseUrl}/auth/profile"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "old_email": oldEmail,
          "new_email": newEmail,
          "full_name": fullName
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return Right(User.fromJson(data['user'] ?? {}));
      } else {
        return Left(data['error'] ?? "Güncelleme başarısız");
      }
    } catch (e) {
      return Left("Bağlantı hatası: $e");
    }
  }
}
