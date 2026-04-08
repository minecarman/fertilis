class Weather {
  final double temp;
  final double humidity;
  final String description;
  final String city;
  final String icon;
  final double wind;
  final String? date;

  Weather({
    required this.temp,
    required this.humidity,
    required this.description,
    required this.city,
    required this.icon,
    required this.wind,
    this.date,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      temp: (json['temp'] ?? 0.0).toDouble(),
      humidity: (json['humidity'] ?? 0.0).toDouble(),
      description: json['description']?.toString() ?? '',
      city: json['city']?.toString() ?? 'Bilinmeyen Konum',
      icon: json['icon']?.toString() ?? '01d',
      wind: (json['wind'] ?? 0.0).toDouble(),
      date: json['date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'temp': temp,
      'humidity': humidity,
      'description': description,
      'city': city,
      'icon': icon,
      'wind': wind,
      'date': date,
    };
  }
}
