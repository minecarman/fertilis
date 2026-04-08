import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../models/recommendation.dart';
import '../models/field.dart';

class RecommendationPage extends StatefulWidget {
  final Field field;

  const RecommendationPage({super.key, required this.field});

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  List<Recommendation> recommendedRecommendations = [];
  bool isLoading = false;
  String errorMessage = '';

  Future<void> fetchRecommendations() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
      recommendedRecommendations = [];
    });

    try {
      double lat = widget.field.center.latitude;
      double lng = widget.field.center.longitude;

      List<Recommendation> results =
          await RecommendationService.getRecommendations(lat, lng);

      setState(() {
        recommendedRecommendations = results;
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
        title: Text('${widget.field.name} - Ürün Önerisi'),
        backgroundColor: Colors.green[700],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.field.name} tarlanızın mevsime ait iklim verileri ve toprak verileri baz alınarak ürün yatkınlık analizi yapılmaktadır.',
              style: TextStyle(fontSize: 16, color: Colors.grey[700]),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            ElevatedButton.icon(
              icon: Icon(Icons.analytics),
              label: Text('Analizi Başlat'),
              onPressed: isLoading ? null : fetchRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[600],
              ),
            ),
            SizedBox(height: 16),
            if (isLoading)
              Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(errorMessage, style: TextStyle(color: Colors.red)),
              )
            else if (recommendedRecommendations.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: recommendedRecommendations.length,
                  itemBuilder: (context, index) {
                    final crop = recommendedRecommendations[index];
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Text(
                            '#${crop.rank}',
                            style: TextStyle(
                              color: Colors.green[800],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          crop.displayName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              crop.description,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              crop.plantingCalendar,
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: Icon(
                          Icons.check_circle_outline,
                          color: Colors.green,
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
