import 'package:flutter/material.dart';

class IrrigationPage extends StatelessWidget {
  const IrrigationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis Irrigation")),
      body: const Center(
        child: Text("Irrigation will be added to this page"),
      ),
    );
  }
}
