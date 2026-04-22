import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  static const String _emailKey = 'auth_user_email';
  static const String _nameKey = 'auth_user_name';

  String? _currentUserEmail;
  String? _currentUserName;

  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _currentUserEmail = prefs.getString(_emailKey);
    _currentUserName = prefs.getString(_nameKey);
    notifyListeners();
  }

  void setUser(String? email, String? name) {
    _currentUserEmail = email;
    _currentUserName = name;
    _saveSession();
    notifyListeners();
  }

  void logout() {
    _currentUserEmail = null;
    _currentUserName = null;
    _clearSession();
    notifyListeners();
  }

  Future<void> _saveSession() async {
    final prefs = await SharedPreferences.getInstance();

    if (_currentUserEmail == null) {
      await prefs.remove(_emailKey);
    } else {
      await prefs.setString(_emailKey, _currentUserEmail!);
    }

    if (_currentUserName == null || _currentUserName!.isEmpty) {
      await prefs.remove(_nameKey);
    } else {
      await prefs.setString(_nameKey, _currentUserName!);
    }
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_emailKey);
    await prefs.remove(_nameKey);
  }
}
