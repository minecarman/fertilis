import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../core/api_config.dart';
import '../models/field.dart';

class FieldService {
  static Future<bool> saveField(Field field) async {
    try {
      final res = await http.post(
        Uri.parse("${ApiConfig.baseUrl}/api/fields/add"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(field.toJson()),
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint("Kayıt Hatası: $e");
      return false;
    }
  }

  static Future<List<Field>> getFields(String email) async {
    try {
      final res = await http.get(Uri.parse("${ApiConfig.baseUrl}/api/fields/$email"));
      if (res.statusCode == 200) {
        return (jsonDecode(res.body) as List).map((e) => Field.fromJson(e)).toList();
      }
      return [];
    } catch (e) {
      debugPrint("Çekme Hatası: $e");
      return [];
    }
  }
}