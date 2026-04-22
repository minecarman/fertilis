import 'dart:math' as math;
import 'dart:convert';
import 'package:latlong2/latlong.dart';

class Field {
  final String? id;
  final String userEmail;
  final String name;
  final double area;
  final List<LatLng> points;
  final String? crop;
  final String? imageUrl;

  List<LatLng> get boundaries => points; 
  double get calculatedArea => calculateAreaHa(points);

  static double calculateAreaHa(List<LatLng> polygon) {
    if (polygon.length < 3) return 0;

    const earthRadius = 6371000.0;
    final avgLat = polygon.fold<double>(0, (sum, point) => sum + point.latitude) / polygon.length;
    final latFactor = earthRadius * (3.141592653589793 / 180.0);
    final lngFactor = earthRadius * (3.141592653589793 / 180.0) * math.cos(avgLat * 3.141592653589793 / 180.0);

    double area = 0;
    for (var i = 0; i < polygon.length; i++) {
      final current = polygon[i];
      final next = polygon[(i + 1) % polygon.length];

      final x1 = current.longitude * lngFactor;
      final y1 = current.latitude * latFactor;
      final x2 = next.longitude * lngFactor;
      final y2 = next.latitude * latFactor;

      area += (x1 * y2) - (x2 * y1);
    }

    return area.abs() / 2 / 10000.0;
  }

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
    this.crop,
    this.imageUrl,
  });

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }

  static List<LatLng> _parsePoints(dynamic coordinatesRaw) {
    if (coordinatesRaw is String) {
      try {
        final decoded = jsonDecode(coordinatesRaw);
        return _parsePoints(decoded);
      } catch (_) {
        return const <LatLng>[];
      }
    }

    if (coordinatesRaw is! List) {
      return const <LatLng>[];
    }

    return coordinatesRaw
        .whereType<Map>()
        .map((p) => LatLng(_toDouble(p['lat']), _toDouble(p['lng'])))
        .toList();
  }

  factory Field.fromJson(Map<String, dynamic> json) {
    final parsedPoints = _parsePoints(json['coordinates']);
    return Field(
      id: json['id'].toString(),
      userEmail: json['user_email'] ?? "",
      name: json['name'] ?? "Adsız",
      area: _toDouble(json['area']),
      points: parsedPoints,
      crop: json['crop']?.toString(),
      imageUrl: json['image_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_email': userEmail,
      'name': name,
      'area': area,
      'coordinates': points.map((p) => {'lat': p.latitude, 'lng': p.longitude}).toList(),
      'crop': crop,
      'image_url': imageUrl,
    };
  }
}