import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/weather.dart';
import '../models/field.dart';
import '../core/theme.dart';

class WeatherPage extends StatefulWidget {
  final Field field; // HomePage'den gelen tarla

  const WeatherPage({super.key, required this.field});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  bool loading = false;
  List<Weather>? forecastData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    // Sayfa açıldığında otomatik olarak veriyi çek
    _fetchWeather();
  }

  void _fetchWeather() async {
    setState(() {
      loading = true;
      forecastData = null;
      errorMessage = null;
    });

    final dataResult = await WeatherService.getForecast(
      widget.field.center.latitude,
      widget.field.center.longitude,
    );

    if (mounted) {
      dataResult.fold(
        (error) {
          setState(() {
            loading = false;
            errorMessage = error;
          });
        },
        (data) {
          setState(() {
            forecastData = data;
            loading = false;
          });
        }
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Seçili tarlayı belirten başlık kısmı
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.map, color: Colors.blueGrey, size: 20),
                const SizedBox(width: 8),
                Text(
                  "${widget.field.name} Havası", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 30),

          if (loading)
            const CircularProgressIndicator()
          else if (errorMessage != null)
             Text(errorMessage!, style: const TextStyle(color: Colors.red))
          else if (forecastData != null && forecastData!.isNotEmpty)
            _buildWeatherInfo()
          else
             const Text("Hava durumu bilgisi alınamadı.", style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    final validForecasts = forecastData!.where((d) {
      if (d.date == null) return true;
      try {
        DateTime date = DateTime.parse(d.date!);
        DateTime now = DateTime.now();
        DateTime today = DateTime(now.year, now.month, now.day);
        DateTime target = DateTime(date.year, date.month, date.day);
        return target.difference(today).inDays >= 0; // Dün ve öncesini kaldır
      } catch (e) {
        return true;
      }
    }).toList();

    if (validForecasts.isEmpty) {
      return const Text("Hava durumu verisi bulunmuyor.", style: TextStyle(color: Colors.grey));
    }

    return Column(
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: validForecasts.length,
          itemBuilder: (context, index) {
            final dayData = validForecasts[index];
            final String dateText = _formatDate(dayData.date);
            final String formalDesc = _formalizeDescription(dayData.description);
            final Widget weatherIcon = _getWeatherIcon(dayData.icon);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 0,
              color: Colors.white,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  children: [
                    weatherIcon,
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateText,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textBlack),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            formalDesc,
                            style: const TextStyle(color: AppTheme.textGrey, fontWeight: FontWeight.w500, fontSize: 14),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(Icons.water_drop_outlined, size: 16, color: AppTheme.wikilocGreen),
                              const SizedBox(width: 4),
                              Text("%${dayData.humidity}", style: const TextStyle(color: AppTheme.textBlack, fontSize: 13, fontWeight: FontWeight.w500)),
                              const SizedBox(width: 16),
                              const Icon(Icons.air, size: 16, color: AppTheme.wikilocGreen),
                              const SizedBox(width: 4),
                              Text("${dayData.wind} km/s", style: const TextStyle(color: AppTheme.textBlack, fontSize: 13, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${dayData.temp}°",
                      style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.darkGreen),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _getWeatherIcon(String iconCode) {
    IconData iconData;
    Color iconColor;

    final String prefix = iconCode.length >= 2 ? iconCode.substring(0, 2) : '01';

    switch (prefix) {
      case '01': // clear sky
        iconData = Icons.wb_sunny;
        iconColor = Colors.orange;
        break;
      case '02': // few clouds
        iconData = Icons.wb_cloudy_outlined;
        iconColor = Colors.amber;
        break;
      case '03': // scattered clouds
      case '04': // broken clouds
        iconData = Icons.cloud_outlined;
        iconColor = Colors.blueGrey;
        break;
      case '09': // shower rain
      case '10': // rain
        iconData = Icons.water_drop;
        iconColor = Colors.blue;
        break;
      case '11': // thunderstorm
        iconData = Icons.flash_on;
        iconColor = Colors.deepPurple;
        break;
      case '13': // snow
        iconData = Icons.ac_unit;
        iconColor = Colors.lightBlue;
        break;
      case '50': // mist
        iconData = Icons.waves;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.cloud;
        iconColor = Colors.blueGrey;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(iconData, size: 32, color: iconColor),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return "Tarih Yok";
    try {
      DateTime date = DateTime.parse(dateStr);
      DateTime now = DateTime.now();
      DateTime today = DateTime(now.year, now.month, now.day);
      DateTime target = DateTime(date.year, date.month, date.day);
      
      const weekdays = ["Pazartesi", "Salı", "Çarşamba", "Perşembe", "Cuma", "Cumartesi", "Pazar"];
      String dayName = weekdays[date.weekday - 1];

      final difference = target.difference(today).inDays;
      if (difference == 0) return "Bugün, $dayName";
      if (difference == 1) return "Yarın, $dayName";
      
      return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}, $dayName";
    } catch (e) {
      return dateStr;
    }
  }

  String _formalizeDescription(String desc) {
    final lowerDesc = desc.toLowerCase().trim();
    if (lowerDesc.contains('hafif yağmur')) return 'Hafif Yağışlı';
    if (lowerDesc.contains('şiddetli yağmur')) return 'Şiddetli Yağışlı';
    if (lowerDesc == 'yağmur' || lowerDesc == 'yağmurlu') return 'Yağışlı';
    if (lowerDesc == 'açık') return 'Açık';
    if (lowerDesc.contains('parçalı bulutlu')) return 'Parçalı Bulutlu';
    if (lowerDesc.contains('az bulutlu')) return 'Az Bulutlu';
    if (lowerDesc.contains('çok bulutlu') || lowerDesc.contains('kapalı')) return 'Çok Bulutlu';
    if (lowerDesc.contains('kar')) return 'Kar Yağışlı';
    
    // Varsayılan olarak her kelimenin baş harfini büyüt
    return desc.split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }
}