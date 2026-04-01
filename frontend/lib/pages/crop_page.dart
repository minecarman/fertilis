import 'package:flutter/material.dart';
import '../services/crop_service.dart';
import '../models/crop.dart';
import '../models/field.dart'; // Field modelini ekledik

class CropPage extends StatefulWidget {
  final Field field; // HomePage'den gelen seçili tarla

  const CropPage({super.key, required this.field});

  @override
  State<CropPage> createState() => _CropPageState();
}

class _CropPageState extends State<CropPage> {
  List<Crop> recommendedCrops = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchRecommendations() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      recommendedCrops = [];
    });

    try {
      // HomePage'de seçtiğin tarlanın orta noktasını kullanıyoruz!
      double lat = widget.field.center.latitude;
      double lng = widget.field.center.longitude;

      List<Crop> results = await CropService.getRecommendations(lat, lng);
      
      setState(() {
        recommendedCrops = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.field.name} - Ürün Önerisi'), // Hangi tarla olduğunu yazar
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.field.name} tarlanızın toprak ve anlık iklim verileri analiz ediliyor.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            // ... (Geri kalan UI kodu aynı kalabilir)
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.analytics),
              label: Text('Analizi Başlat'),
              onPressed: isLoading ? null : fetchRecommendations,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green[600]),
            ),
            // ...
            if (isLoading) Center(child: CircularProgressIndicator())
            else if (recommendedCrops.isNotEmpty) 
              // Önerileri gösteren ListView...
              Expanded(child: ListView.builder(
                itemCount: recommendedCrops.length,
                itemBuilder: (context, index) => Card( /*...*/ ),
              ))
          ],
        ),
      ),
    );
  }
}