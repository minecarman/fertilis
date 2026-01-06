import 'package:latlong2/latlong.dart';

class Field {
  final String id;
  final String name;
  final List<LatLng> boundaries; // Tarlanın sınırları
  final LatLng center; // Hava durumu sorgusu için orta nokta

  Field({
    required this.id,
    required this.name,
    required this.boundaries,
    required this.center,
  });
}