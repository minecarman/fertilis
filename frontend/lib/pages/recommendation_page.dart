import 'package:flutter/material.dart';
import '../services/crop_service.dart';

class RecommendationPage extends StatelessWidget {
  const RecommendationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis Recommendation")),
      body: FutureBuilder(
        future: CropService.getRecommendation(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final crop = snapshot.data!;
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("Öneri:: ${crop.name}",
                    style: const TextStyle(fontSize: 20)),
                Text("Çünkü:: ${crop.reason}"),
              ],
            ),
          );
        },
      ),
    );
  }
}
