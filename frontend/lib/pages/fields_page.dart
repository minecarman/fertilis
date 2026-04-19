import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/field.dart';
import '../services/field_service.dart';
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
  
  final LatLng _center = const LatLng(37.1627, 28.3712);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFields();
    });
  }

  void _loadFields() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String email = authProvider.currentUserEmail ?? "test@user.com";
    final fieldsResult = await FieldService.getFields(email);
    
    if (mounted) {
      fieldsResult.fold(
        (error) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        },
        (fields) {
          setState(() {
            myFields = fields;
          });
        }
      );
    }
  }

  Future<void> _moveToCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Konum servisi kapalı.")));
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _mapController.move(LatLng(position.latitude, position.longitude), 16.0);
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

  void _showSaveDialog() {
    if (_currentPoints.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("En az 3 nokta gerekli!")),
      );
      return;
    }

    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tarlayı Kaydet"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: "Tarla Adı (Örn: Aşağı Zeytinlik)",
            icon: Icon(Icons.label),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _saveFieldToBackend(nameController.text);
            },
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  void _saveFieldToBackend(String name) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String email = authProvider.currentUserEmail ?? "test@user.com";
    
    final newField = Field(
      userEmail: email,
      name: name.isEmpty ? "Yeni Tarla ${myFields.length + 1}" : name,
      area: 10.0, 
      points: List.from(_currentPoints),
    );

    final result = await FieldService.saveField(newField);

    if (!mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error), backgroundColor: AppTheme.errorClay));
      },
      (_) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Tarla başarıyla kaydedildi!")));
        setState(() {
          _isDrawing = false;
          _currentPoints.clear();
        });
        _loadFields(); 
      }
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
              TileLayer(
                urlTemplate: 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png',
                subdomains: const ['a', 'b', 'c', 'd'],
                userAgentPackageName: 'com.fertilis.frontend',
                maxZoom: 20,
              ),
              
              PolygonLayer(
                polygons: myFields.map((field) {
                  return Polygon(
                    points: field.points,
                    color: AppTheme.wikilocGreen.withValues(alpha: 0.4), 
                    borderColor: AppTheme.darkGreen, 
                    borderStrokeWidth: 2,
                    label: field.name,
                    labelStyle: const TextStyle(color: AppTheme.textBlack, fontWeight: FontWeight.bold),
                  );
                }).toList(),
              ),

              if (_isDrawing && _currentPoints.isNotEmpty)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: _currentPoints,
                      color: AppTheme.mossGreen.withValues(alpha: 0.35),
                      borderColor: AppTheme.mossGreen,
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
                          color: AppTheme.backgroundGrey,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.mossGreen, width: 2),
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
                  color: AppTheme.darkGreen,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [BoxShadow(color: AppTheme.darkGreen.withValues(alpha: 0.35), blurRadius: 10)],
                ),
                child: Text(
                  _currentPoints.isEmpty 
                      ? "Haritaya dokunarak sınırları belirle" 
                      : "${_currentPoints.length} nokta eklendi",
                  style: const TextStyle(color: AppTheme.backgroundGrey, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

          Positioned(
            bottom: 100,
            right: 20,
            child: FloatingActionButton(
              heroTag: "gps_btn",
              backgroundColor: AppTheme.surfaceOlive,
              mini: true,
              onPressed: _moveToCurrentLocation,
              child: const Icon(Icons.my_location, color: AppTheme.textBlack),
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
                    backgroundColor: AppTheme.surfaceOlive,
                    foregroundColor: AppTheme.errorClay,
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: "save_btn",
                    onPressed: _showSaveDialog,
                    label: const Text("Bitir"),
                    icon: const Icon(Icons.check),
                    backgroundColor: AppTheme.wikilocGreen, 
                    foregroundColor: AppTheme.backgroundGrey,
                  ),
                ] else ...[
                  FloatingActionButton.extended(
                    heroTag: "add_btn",
                    onPressed: () => setState(() { _isDrawing = true; _currentPoints.clear(); }),
                    label: const Text("Yeni Tarla Çiz"),
                    icon: const Icon(Icons.add_location_alt_outlined),
                    backgroundColor: AppTheme.surfaceOlive,
                    foregroundColor: AppTheme.wikilocGreen,
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