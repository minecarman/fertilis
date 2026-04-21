import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/field.dart';
import '../models/yield_prediction.dart';
import '../services/yield_service.dart';

class YieldPage extends StatefulWidget {
  final Field field;

  const YieldPage({super.key, required this.field});

  @override
  State<YieldPage> createState() => _YieldPageState();
}

class _YieldPageState extends State<YieldPage> {
  bool loading = false;
  String? error;
  YieldPrediction? result;

  // Crop names mapping: English -> Turkish
  final Map<String, String> cropNames = {
    'Wheat': 'Buğday',
    'Maize': 'Mısır',
    'Rice': 'Pirinç',
    'Soybean': 'Soya',
    'Barley': 'Arpa',
    'Oats': 'Yulaf',
    'Rye': 'Çavdar',
    'COARSE GRAINS': 'Iri Tahıllar',
  };

  String? selectedCropEn; // English name for API
  final TextEditingController commodityController = TextEditingController();

  @override
  void dispose() {
    commodityController.dispose();
    super.dispose();
  }

  Future<void> runPrediction() async {
    if (selectedCropEn == null || selectedCropEn!.isEmpty) {
      setState(() => error = "Lütfen bir ekin seçiniz");
      return;
    }

    setState(() {
      loading = true;
      error = null;
      result = null;
    });

    final response = await YieldService.predictByCoordinates(
      commodity: selectedCropEn!,
      lat: widget.field.center.latitude,
      lng: widget.field.center.longitude,
    );

    setState(() {
      response.fold((err) => error = err, (data) => result = data);
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                Icon(Icons.insights, color: AppTheme.mossGreen),
                SizedBox(width: 10),
                Expanded(
                  child: Text("Seçili tarlanız için ekin verimi tahmini yapın."),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOlive,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.surfaceMoss),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Crop Dropdown
                DropdownButtonFormField<String>(
                  initialValue: selectedCropEn,
                  decoration: const InputDecoration(
                    labelText: "Ekin Seçiniz",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.agriculture),
                  ),
                  items: cropNames.entries.map((entry) {
                    return DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedCropEn = value;
                      error = null;
                    });
                  },
                ),
                const SizedBox(height: 14),

                // Field info
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundGrey,
                    border: Border.all(color: AppTheme.surfaceMoss),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Seçili Tarla: ${widget.field.name}",
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "Konum: ${widget.field.center.latitude.toStringAsFixed(2)}, ${widget.field.center.longitude.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Predict button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading || selectedCropEn == null ? null : runPrediction,
                    icon: loading ? const SizedBox.shrink() : const Icon(Icons.query_stats),
                    label: loading 
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Tahmini Hesapla"),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Error
          if (error != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red[100],
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                error!,
                style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
              ),
            ),

          // Result
          if (result != null) ...[
            const SizedBox(height: 16),
            _buildResult(result!),
          ],
        ],
      ),
    );
  }

  Widget _buildResult(YieldPrediction data) {
    final prediction = data.prediction;
    final cropTr = cropNames[prediction.commodity] ?? prediction.commodity;
    
    // Trend info
    Color trendColor = Colors.grey;
    IconData trendIcon = Icons.trending_flat;
    String trendTr = 'Sabit';
    
    if (prediction.trend == 'increase') {
      trendColor = Colors.green;
      trendIcon = Icons.trending_up;
      trendTr = 'Artış Bekleniyor';
    } else if (prediction.trend == 'decrease') {
      trendColor = Colors.red;
      trendIcon = Icons.trending_down;
      trendTr = 'Düşüş Bekleniyor';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceMoss,
        border: Border.all(color: AppTheme.darkKhaki),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            cropTr,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
          const SizedBox(height: 16),

          // Main value
          Text(
            prediction.predictedProductionMt.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppTheme.wikilocGreen,
            ),
          ),
          const Text(
            "Ton/Hektar",
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),

          // Trend badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: trendColor.withValues(alpha: 0.1),
              border: Border.all(color: trendColor),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(trendIcon, color: trendColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  trendTr,
                  style: TextStyle(
                    color: trendColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Details
          if (prediction.currentProductionMt != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Mevcut Ortalama", style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text("${prediction.currentProductionMt!.toStringAsFixed(1)} T/H"),
              ],
            ),
            const SizedBox(height: 8),
          ],

          if (prediction.deltaMt != null) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Değişim", style: TextStyle(fontSize: 13, color: Colors.grey)),
                Text(
                  "${prediction.deltaMt!.toStringAsFixed(1)} T/H",
                  style: TextStyle(
                    color: (prediction.deltaMt ?? 0) > 0 ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Sezon", style: TextStyle(fontSize: 13, color: Colors.grey)),
              Text(prediction.latestSeason),
            ],
          ),
        ],
      ),
    );
  }
}
