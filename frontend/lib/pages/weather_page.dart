import 'package:flutter/material.dart';

class WeatherPage extends StatelessWidget {
  const WeatherPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis Havadurumu")),
      body: const Center(
        child: Text("hava durumu yabacam :P"),
      ),
    );
  }
}
