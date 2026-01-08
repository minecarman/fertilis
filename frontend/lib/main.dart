import 'package:flutter/material.dart';
import 'core/theme.dart';
//import 'pages/home_page.dart';
import 'pages/login_page.dart';

void main() {
  runApp(const Fertilis());
}

class Fertilis extends StatelessWidget {
  const Fertilis({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fertilis',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      home: const LoginPage(),
    );
  }
}
