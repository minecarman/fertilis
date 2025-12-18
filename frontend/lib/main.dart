import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const Fertilis());
}

class Fertilis extends StatelessWidget {
  const Fertilis({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fertilis',
      theme: appTheme,
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
