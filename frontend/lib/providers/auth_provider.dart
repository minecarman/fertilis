import 'package:flutter/material.dart';

class AuthProvider extends ChangeNotifier {
  String? _currentUserEmail;
  String? _currentUserName;

  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;

  void setUser(String? email, String? name) {
    _currentUserEmail = email;
    _currentUserName = name;
    notifyListeners(); // UI'ı günceller
  }

  void logout() {
    _currentUserEmail = null;
    _currentUserName = null;
    notifyListeners();
  }
}
