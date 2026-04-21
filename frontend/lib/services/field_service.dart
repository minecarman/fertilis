import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';
import '../models/field.dart';

class FieldService {
  static Future<Either<String, String>> uploadFieldImage({
    required String userEmail,
    required String imageBase64,
    required String fileName,
  }) async {
    try {
      debugPrint("[FieldService.uploadFieldImage] POST ${ApiConfig.baseUrl}/api/v1/fields/upload-image");
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/fields/upload-image"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "user_email": userEmail,
          "image_base64": imageBase64,
          "file_name": fileName,
        }),
      ).timeout(const Duration(seconds: 25));

      debugPrint("[FieldService.uploadFieldImage] status=${res.statusCode} body=${res.body}");

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final imageUrl = (data['image_url'] ?? '').toString();
        if (imageUrl.isNotEmpty) return Right(imageUrl);
      }

      return Left("Fotoğraf yüklenemedi. Sunucu yanıtı: ${res.statusCode} ${res.body}");
    } on TimeoutException {
      return const Left("Fotoğraf yükleme zaman aşımına uğradı.");
    } catch (e) {
      debugPrint("Fotoğraf Yükleme Hatası: $e");
      return Left("Bağlantı Hatası: $e");
    }
  }

  static Future<Either<String, bool>> saveField(Field field) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/fields/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(field.toJson()),
      ).timeout(const Duration(seconds: 20));
      
      if (res.statusCode == 201) return const Right(true);
      return const Left("Tarla kaydedilirken bir sunucu hatası oluştu.");
    } on TimeoutException {
      return const Left("Tarla kaydı zaman aşımına uğradı.");
    } catch (e) {
      debugPrint("Kayıt Hatası: $e");
      return Left("Bağlantı Hatası: $e");
    }
  }

  static Future<Either<String, bool>> deleteField(int fieldId) async {
    try {
      final res = await http.delete(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/fields/$fieldId"),
        headers: {"Content-Type": "application/json"},
      );
      if (res.statusCode == 200) return const Right(true);
      return const Left("Tarla silinirken bir sunucu hatası oluştu.");
    } catch (e) {
      debugPrint("Silme Hatası: $e");
      return Left("Bağlantı Hatası: $e");
    }
  }

  static Future<Either<String, List<Field>>> getFields(String email) async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/api/v1/fields/$email"));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        return Right(data.map((e) => Field.fromJson(e)).toList());
      }
      return Left("Tarlalar getirilemedi. Durum kodu: ${res.statusCode}");
    } catch (e) {
      debugPrint("Çekme Hatası: $e");
      return Left("Bağlantı Hatası: $e");
    }
  }
}