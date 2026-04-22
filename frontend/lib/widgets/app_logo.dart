import 'package:flutter/material.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.height = 45,
    this.assetPath = 'assets/images/full_logo_transparent.png',
    this.alignment = Alignment.centerLeft,
  });

  final double height;
  final String assetPath;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Image.asset(
        assetPath,
        height: height,
        fit: BoxFit.contain,
        alignment: alignment,
      ),
    );
  }
}