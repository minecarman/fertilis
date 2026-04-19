import 'package:flutter/material.dart';
import '../services/recommendation_service.dart';
import '../models/recommendation.dart';
import '../models/field.dart';
import '../core/theme.dart';

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
        backgroundColor: AppTheme.surfaceOlive,
        foregroundColor: AppTheme.darkGreen,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.field.name} tarlanızın mevsime ait iklim verileri ve toprak verileri baz alınarak ürün yatkınlık analizi yapılmaktadır.',
              style: const TextStyle(fontSize: 16, color: AppTheme.textGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              icon: const Icon(Icons.analytics),
              label: const Text('Analizi Başlat'),
              onPressed: isLoading ? null : fetchRecommendations,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.wikilocGreen,
                foregroundColor: AppTheme.backgroundGrey,
              ),
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Center(child: CircularProgressIndicator())
            else if (errorMessage.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(errorMessage, style: const TextStyle(color: AppTheme.errorClay)),
              )
            else if (recommendedRecommendations.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: recommendedRecommendations.length,
                  itemBuilder: (context, index) {
                    final crop = recommendedRecommendations[index];
                    return Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.surfaceMoss,
                          child: Text(
                            '#${crop.rank}',
                            style: const TextStyle(
                              color: AppTheme.darkGreen,
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
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textBlack,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              crop.plantingCalendar,
                              style: const TextStyle(
                                color: AppTheme.textGrey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        isThreeLine: true,
                        trailing: const Icon(
                          Icons.check_circle_outline,
                          color: AppTheme.mossGreen,
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
