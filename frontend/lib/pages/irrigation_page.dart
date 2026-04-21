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
                Expanded(child: Text("Seçili tarlanızın su ihtiyacı hesaplanır. Yeşil = Yeterli yağış, Turuncu = Sulama gerekli.")),
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
                color: resultStr!.irrigationMm <= 0 ? AppTheme.surfaceMoss : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: resultStr!.irrigationMm <= 0 ? AppTheme.mossGreen : Colors.orange,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Main recommendation
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: resultStr!.irrigationMm <= 0 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: resultStr!.irrigationMm <= 0 ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          resultStr!.irrigationMm <= 0 ? "Sulama Gerekmez" : "Sulama Gerekli",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: resultStr!.irrigationMm <= 0 ? Colors.green : Colors.orange[800],
                          ),
                        ),
                        if (resultStr!.irrigationMm > 0) ...[
                          const SizedBox(height: 8),
                          Text(
                            "${resultStr!.irrigationMm.toStringAsFixed(0)} mm",
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Detailed breakdown
                  Column(
                    children: [
                      _detailRow("Ölçülen Yağış", "${resultStr!.rawRainMm.toStringAsFixed(1)} mm"),
                      _detailRow("Buharlaşma (ET0)", "${resultStr!.et0Mm.toStringAsFixed(1)} mm"),
                      _detailRow("Bitki Su Kaybı", "${resultStr!.cropWaterLossMm.toStringAsFixed(1)} mm"),
                      _detailRow("Efektif Yağış", "${resultStr!.effectiveRainMm.toStringAsFixed(1)} mm"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _tag("Toprak", resultStr!.soilType),
                      _tag("AMC", resultStr!.amc),
                      _tag("Kaynak", resultStr!.weatherSource),
                    ],
                  ),
                ],
              ),
            )
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _tag(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.surfaceOlive,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surfaceMoss),
      ),
      child: Text("$label: $value", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}