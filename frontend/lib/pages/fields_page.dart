import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart';
import '../models/field.dart';
import '../core/theme.dart';


List<Field> myFields = [];

class FieldsPage extends StatefulWidget {
  const FieldsPage({super.key});

  @override
  State<FieldsPage> createState() => _FieldsPageState();
}

class _FieldsPageState extends State<FieldsPage> {
  final MapController _mapController = MapController();
  
  bool _isDrawing = false;
  final List<LatLng> _currentPoints = [];
  
  // mskü ilk konum
  final LatLng _center = const LatLng(37.1627, 28.3712); 

  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konum servisi kapalı. Lütfen açınız.")),
        );
      }
      return;
    }


    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Konum izni verilmedi.")),
          );
        }
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Konum izni kalıcı olarak reddedildi, ayarlardan açmalısınız.")),
        );
      }
      return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(
        LatLng(position.latitude, position.longitude), 
        16.0 
      );
    } catch (e) {
      debugPrint("Konum hatası: $e");
    }
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawing) {
      setState(() {
        _currentPoints.add(point);
      });
    }
  }

  void _saveField() {
    if (_currentPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Bir alan oluşturmak için en az 3 nokta seçmelisin!")),
      );
      return;
    }

    final TextEditingController nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tarlayı Kaydet"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: "Tarla Adı (Örn: Kuzey Yonca)"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              
              final newField = Field(
                id: const Uuid().v4(),
                name: nameController.text.isEmpty ? "Tarla ${myFields.length+1}" : nameController.text,
                boundaries: List.from(_currentPoints),
                center: _currentPoints[0], 
              );
              
              setState(() {
                myFields.add(newField);
                _currentPoints.clear();
                _isDrawing = false;
              });
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Tarla başarıyla kaydedildi!")),
              );
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 15.0,
              onTap: _handleTap, 
            ),
            children: [
              TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
              
              PolygonLayer(
                polygons: myFields.map((field) {
                  return Polygon(
                    points: field.boundaries,
                    color: AppTheme.wikilocGreen.withValues(alpha: 0.4),
                    borderColor: AppTheme.darkGreen,
                    borderStrokeWidth: 2,
                    label: field.name,
                  );
                }).toList(),
              ),

              if (_isDrawing && _currentPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _currentPoints,
                      color: Colors.blue.withValues(alpha: 0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 2,
                    ),
                  ],
                ),
                
              if (_isDrawing)
                MarkerLayer(
                  markers: _currentPoints.map((point) {
                    return Marker(
                      point: point,
                      width: 15,
                      height: 15,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 2),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ),
          
          if (_isDrawing)
            Positioned(
              top: 50,
              left: 20, right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Text(
                  _currentPoints.isEmpty 
                      ? "Haritaya dokunarak köşeleri belirle" 
                      : "${_currentPoints.length} nokta eklendi",
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              heroTag: "gps_btn",
              backgroundColor: Colors.white,
              mini: true,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.black87),
            ),
          ),

          Positioned(
            bottom: 30, 
            left: 20, 
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                if (_isDrawing) ...[
                  FloatingActionButton.extended(
                    heroTag: "cancel_btn",
                    onPressed: () => setState(() { _isDrawing = false; _currentPoints.clear(); }),
                    label: const Text("İptal"),
                    icon: const Icon(Icons.close),
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red,
                    elevation: 4,
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: "save_btn",
                    onPressed: _saveField,
                    label: const Text("Kaydet"),
                    icon: const Icon(Icons.check),
                    backgroundColor: AppTheme.wikilocGreen, // renk
                    foregroundColor: Colors.white,
                    elevation: 4,
                  ),
                ] else ...[
                  FloatingActionButton.extended(
                    heroTag: "add_btn",
                    onPressed: () => setState(() { _isDrawing = true; _currentPoints.clear(); }),
                    label: const Text("Yeni Tarla Çiz"),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    backgroundColor: Colors.white,
                    foregroundColor: AppTheme.wikilocGreen,
                    elevation: 4,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}