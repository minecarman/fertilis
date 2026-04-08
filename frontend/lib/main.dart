import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'pages/login_page.dart';
import 'providers/auth_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
      ],
      child: const Fertilis(),
    ),
  );
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
