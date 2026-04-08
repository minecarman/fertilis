import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fpdart/fpdart.dart';
import '../core/api_config.dart';
import '../models/field.dart';

class FieldService {
  static Future<Either<String, bool>> saveField(Field field) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/v1/fields/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(field.toJson()),
      );
      
      if (res.statusCode == 201) return const Right(true);
      return const Left("Tarla kaydedilirken bir sunucu hatası oluştu.");
    } catch (e) {
      debugPrint("Kayıt Hatası: $e");
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