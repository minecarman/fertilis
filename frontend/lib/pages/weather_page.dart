import 'package:flutter/material.dart';
import '../services/weather_service.dart';
import '../models/field.dart';
import 'fields_page.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState() => _WeatherPageState();
}

class _WeatherPageState extends State<WeatherPage> {
  Field? _selectedField;
  bool loading = false;
  Map<String, dynamic>? weatherData;

  void _fetchWeather(Field field) async {
    setState(() {
      _selectedField = field;
      loading = true;
      weatherData = null;
    });

    final data = await WeatherService.getWeather(
      field.center.latitude,
      field.center.longitude,
    );

    setState(() {
      weatherData = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<Field>(
                isExpanded: true,
                hint: const Text("Hangi tarlanın havasına bakacağız?"),
                value: _selectedField,
                items: myFields.map((field) {
                  return DropdownMenuItem(
                    value: field,
                    child: Text(field.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) _fetchWeather(val);
                },
              ),
            ),
          ),
          
          // hiç tarla yoksa uyarı
          if (myFields.isEmpty)
             Padding(
               padding: const EdgeInsets.only(top: 12.0),
               child: Text(
                 "Henüz kayıtlı tarlan yok. Önce haritadan ekle.", 
                 style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
               ),
             ),

          const SizedBox(height: 30),

          if (loading)
            const CircularProgressIndicator()
          else if (weatherData != null)
            _buildWeatherInfo()
          else if (_selectedField != null)
             const Text("Hava durumu bilgisi alınamadı.", style: TextStyle(color: Colors.red)),
        ],
      ),
    );
  }

  Widget _buildWeatherInfo() {
    return Column(
      children: [
        Text(
          weatherData!['city'] ?? "Bilinmeyen Konum",
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        
        const SizedBox(height: 10),

        // OpenWeatherMap ikon
        Image.network(
          "https://openweathermap.org/img/wn/${weatherData!['icon']}@4x.png",
          width: 120,
          height: 120,
          errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny, size: 80, color: Colors.orange),
        ),

        // sıcaklık
        Text(
          "${weatherData!['temp']}°C",
          style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.blueAccent),
        ),
        
        // hava acıklaması
        Text(
          weatherData!['description'].toString().toUpperCase(),
          style: const TextStyle(fontSize: 16, letterSpacing: 1.2, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 30),

        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _detailItem(Icons.water_drop, "${weatherData!['humidity']}%", "Nem"),
              Container(height: 40, width: 1, color: Colors.blue.shade200),
              _detailItem(Icons.air, "${weatherData!['wind']} km/s", "Rüzgar"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.blueGrey),
        const SizedBox(height: 5),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}