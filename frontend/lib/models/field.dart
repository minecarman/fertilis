import 'package:latlong2/latlong.dart';

class Field {
  final String? id;
  final String userEmail;
  final String name;
  final double area;
  final List<LatLng> points;

  List<LatLng> get boundaries => points; 
  LatLng get center {
    if (points.isEmpty) return const LatLng(0, 0);
    double lat = 0, lng = 0;
    for (var p in points) { lat += p.latitude; lng += p.longitude; }
    return LatLng(lat / points.length, lng / points.length);
  }

  Field({
    this.id,
    required this.userEmail,
    required this.name,
    required this.area,
    required this.points,
  });

  factory Field.fromJson(Map<String, dynamic> json) {
    var coords = json['coordinates'] as List;
    return Field(
      id: json['id'].toString(),
      userEmail: json['user_email'] ?? "",
      name: json['name'] ?? "Adsız",
      area: (json['area'] ?? 0).toDouble(),
      points: coords.map((p) => LatLng(p['lat'], p['lng'])).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_email': userEmail,
      'name': name,
      'area': area,
      'coordinates': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
    };
  }
}