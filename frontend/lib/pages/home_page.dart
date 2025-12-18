import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'irrigation_page.dart';
import 'recommendation_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text("Chatbot"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              ),
            ),
            ElevatedButton(
              child: const Text("Irrigation"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IrrigationPage()),
              ),
            ),
            ElevatedButton(
              child: const Text("Crop Recommendation"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecommendationPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
