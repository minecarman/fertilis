import 'package:flutter/material.dart';
import '../services/irrigation_service.dart';
import '../models/irrigation_data.dart';
import '../models/field.dart';
import '../models/crop_catalog.dart';
import '../core/theme.dart';

const Map<String, int> _cropIrrigationDays = {
  'almond': 10,
  'apple': 10,
  'banana': 3,
  'barley': 14,
  'blackgram': 12,
  'chickpea': 15,
  'citrus': 10,
  'coconut': 7,
  'coffee': 10,
  'cotton': 14,
  'fig': 14,
  'grape': 14,
  'hazelnut': 10,
  'jute': 7,
  'kidneybeans': 7,
  'lentil': 15,
  'maize': 7,
  'mango': 14,
  'mothbeans': 20,
  'mungbean': 12,
  'muskmelon': 7,
  'olive': 20,
  'onion': 5,
  'orange': 10,
  'papaya': 4,
  'pigeonpeas': 15,
  'pomegranate': 14,
  'potato': 5,
  'rice': 2,
  'sugarbeet': 10,
  'sugarcane': 10,
  'sunflower': 14,
  'tea': 7,
  'tomato': 5,
  'watermelon': 10,
  'wheat': 15,
};

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
  final TextEditingController _lastIrrigatedController = TextEditingController();

  bool get _cropMissing => normalizeCropName(widget.field.crop) == null;

  @override
  void dispose() {
    _lastIrrigatedController.dispose();
    super.dispose();
  }

  int? _parseLastIrrigatedDays() {
    final raw = _lastIrrigatedController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  int _recommendedDaysForCrop(String cropKey) {
    return _cropIrrigationDays[cropKey] ?? 7;
  }

  IrrigationData _buildNoIrrigationResult(String cropKey, int lastIrrigatedDays, int recommendedDays) {
    return IrrigationData(
      rain: '0.00',
      decision: 'Sulama gereksiz',
      mode: 'local-threshold',
      soilType: 'local',
      crop: cropKey,
      amc: '-',
      rawRainMm: 0,
      et0Mm: 0,
      effectiveRainMm: 0,
      cropWaterLossMm: 0,
      baseIrrigationMm: 0,
      irrigationMm: 0,
      recommendedIrrigationDays: recommendedDays,
      lastIrrigatedDays: lastIrrigatedDays,
      timingFactor: 0,
      weatherSource: 'local-threshold',
      scheduleStatus: 'Sulama gereksiz',
    );
  }

  Future<void> analyze() async {
    if (_cropMissing) {
      setState(() {
        errorStr = "Bu tarla için önce ekin seçin. Sulama analizini başlatmak için crop gereklidir.";
      });
      return;
    }

    final lastIrrigatedDays = _parseLastIrrigatedDays();
    final cropKey = normalizeCropName(widget.field.crop);

    if (cropKey == null) {
      setState(() {
        errorStr = "Bu tarla için önce ekin seçin. Sulama analizini başlatmak için crop gereklidir.";
      });
      return;
    }

    if (lastIrrigatedDays == null || lastIrrigatedDays < 0) {
      setState(() {
        errorStr = "Lütfen son sulamayı gün cinsinden girin.";
      });
      return;
    }

    final recommendedDays = _recommendedDaysForCrop(cropKey);

    if (lastIrrigatedDays < recommendedDays) {
      setState(() {
        loading = false;
        resultStr = _buildNoIrrigationResult(cropKey, lastIrrigatedDays, recommendedDays);
        errorStr = null;
      });
      return;
    }

    setState(() {
      loading = true;
      resultStr = null;
      errorStr = null;
    });

    final fetchResult = await IrrigationService.analyzeRain(
      widget.field.center.latitude,
      widget.field.center.longitude,
      crop: cropKey,
      lastIrrigatedDays: lastIrrigatedDays,
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
    final cropKey = normalizeCropName(widget.field.crop);
    final cropLabel = cropKey == null ? "Yok" : translateCropName(cropKey);
    final hasRecommendation = resultStr != null;
    final isIrrigationNeeded = hasRecommendation ? resultStr!.decision.toLowerCase().contains("gerekli") : false;

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
                Expanded(child: Text("Seçili tarlanızın su ihtiyacı hesaplanır.")),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          if (_cropMissing)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppTheme.surfaceMoss,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.errorClay),
              ),
              child: const Text(
                "Bu tarlada ekin seçilmemiş. Sulama analizini kullanmak için önce ekin seçin.",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          if (_cropMissing) const SizedBox(height: 16),

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

                const SizedBox(height: 12),
                _detailRow("Ekin Türü", cropLabel),

                const SizedBox(height: 16),
                TextField(
                  controller: _lastIrrigatedController,
                  keyboardType: TextInputType.number,
                  enabled: !_cropMissing,
                  decoration: const InputDecoration(
                    labelText: "En son kaç gün önce suladın?",
                    hintText: "Örn. 5",
                    suffixText: "gün önce",
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading || _cropMissing ? null : analyze,
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
                color: !isIrrigationNeeded ? AppTheme.surfaceMoss : Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: !isIrrigationNeeded ? AppTheme.mossGreen : Colors.orange,
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
                        color: !isIrrigationNeeded 
                          ? Colors.green.withValues(alpha: 0.1) 
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !isIrrigationNeeded ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          isIrrigationNeeded ? "Sulama Gerekli" : "Sulama Gerekmez",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: !isIrrigationNeeded ? Colors.green : Colors.orange[800],
                          ),
                        ),
                        if (isIrrigationNeeded) ...[
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
                      _detailRow("Bitki Su Kaybı", "${resultStr!.cropWaterLossMm.toStringAsFixed(1)} mm"),
                      _detailRow("Son Sulama", "${resultStr!.lastIrrigatedDays} gün önce"),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Tags
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    alignment: WrapAlignment.center,
                    children: [
                      _tag("Ekin", translateCropName(resultStr!.crop)),
                      _tag("Kaynak", "open-meteo"),
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