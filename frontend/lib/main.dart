import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/app_router.dart';
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
    return MaterialApp.router(
      title: 'Fertilis',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: AppRouter.router,
    );
  }
}
