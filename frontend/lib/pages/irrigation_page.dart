import 'package:flutter/material.dart';
import '../services/irrigation_service.dart';

class IrrigationPage extends StatefulWidget {
  const IrrigationPage({super.key});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}


class _IrrigationPageState extends State<IrrigationPage> { 
  final latController = TextEditingController(); // konum için latitude, longitude değişkenleri
  final lonController = TextEditingController();

  bool loading = false;
  Map<String, dynamic>? result;

  Future<void> analyze() async {
    final lat = double.tryParse(latController.text);
    final lon = double.tryParse(lonController.text);

    if (lat == null || lon == null) return;

    setState(() {
      loading = true;
      result = null;
    });

    final data = await IrrigationService.analyzeRain(lat, lon);

    setState(() {
      result = data;
      loading = false;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fertilis Sulama Asistanı")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            Card(   // SULAMA TAKVIMI BURA YAPILACAK
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "Takvim",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      "Takvim yabacam :P",
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Bugün sulamalı mısın?",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),

                    TextField( // Input lat
                      controller: latController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Enlem"),
                    ),
                    TextField( // Input lon
                      controller: lonController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: "Boylam"),
                    ),

                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: loading ? null : analyze,
                      child: const Text("Kontrol Et"),
                    ),

                    const SizedBox(height: 12),

                    if (loading) const CircularProgressIndicator(),

                    if (result != null) ...[  // SONUÇ KISMI
                      const SizedBox(height: 12),
                      Text("Yağış: ${result!["rain"]} mm"),
                      const SizedBox(height: 6),
                      Text(
                        "Sonuç: ${result!["decision"]}",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
