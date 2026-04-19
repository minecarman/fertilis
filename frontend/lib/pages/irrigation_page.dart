import 'package:flutter/material.dart';
import '../services/irrigation_service.dart';
import '../models/irrigation_data.dart';
import '../models/field.dart';
import '../core/theme.dart';

class IrrigationPage extends StatefulWidget {
  final Field field; // HomePage'den gelen tarla

  const IrrigationPage({super.key, required this.field});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
  bool loading = false;
  IrrigationData? resultStr;
  String? errorStr;

  Future<void> analyze() async {
    setState(() {
      loading = true;
      resultStr = null;
      errorStr = null;
    });

    // Artık seçili tarla kontrolüne gerek yok, widget.field doğrudan kullanılıyor
    final fetchResult = await IrrigationService.analyzeRain(
      widget.field.center.latitude, 
      widget.field.center.longitude
    );

    setState(() {
      fetchResult.fold(
        (err) => errorStr = err,
        (data) => resultStr = data,
      );
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMoss,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.darkKhaki),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: AppTheme.mossGreen),
                SizedBox(width: 12),
                Expanded(child: Text("FAO-56 standardına göre, tarlanızın konumundaki buharlaşma verisi hesaplanır.")),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOlive,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.surfaceMoss),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Analiz Edilecek Tarla", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                // Dropdown yerine seçili tarlayı gösteren şık bir kutu
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGrey,
                    border: Border.all(color: AppTheme.surfaceMoss),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.mossGreen, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        widget.field.name, 
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : analyze,
                    icon: const Icon(Icons.water_drop),
                    label: const Text("Analiz Et"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (loading) const CircularProgressIndicator(),
          if (errorStr != null) Text(errorStr!, style: const TextStyle(color: AppTheme.errorClay)),
          
          if (resultStr != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: resultStr!.decision.contains("gerek yok") ? AppTheme.surfaceMoss : AppTheme.darkKhaki.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: resultStr!.decision.contains("gerek yok") ? AppTheme.mossGreen : AppTheme.darkKhaki),
              ),
              child: Column(
                children: [
                  Text("Tahmini Yağış: ${resultStr!.rain} mm", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(resultStr!.decision, textAlign: TextAlign.center),
                ],
              ),
            )
        ],
      ),
    );
  }
}