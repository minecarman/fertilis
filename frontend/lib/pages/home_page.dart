import 'package:flutter/material.dart';
import 'chat_page.dart';
import 'irrigation_page.dart';
import 'recommendation_page.dart';
import 'weather_page.dart';
import 'wiki_page.dart';
import 'yield_page.dart';

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
              child: const Text("Sohbet Et"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatPage()),
              ),
            ),

                const SizedBox(height: 20),

            ElevatedButton(
              child: const Text("Sulama"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const IrrigationPage()),
              ),
            ),

                const SizedBox(height: 20),

            ElevatedButton(
              child: const Text("Ekinler"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const RecommendationPage()),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: const Text("Hava Durumu"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeatherPage()),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: const Text("Wiki Sayfası"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WikiPage()),
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              child: const Text("Kazançlar"),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const YieldPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
