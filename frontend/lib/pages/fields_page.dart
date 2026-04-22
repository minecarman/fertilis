import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart'; 
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
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
  static const int _maxImageBytes = 4 * 1024 * 1024;
  static const int _maxDrawPoints = 80;
  static const double _minZoom = 5.0;
  static const double _maxZoom = 19.0;
  static const double _fieldLabelZoomThreshold = 13.5;
  
  bool _isDrawing = false;
  bool _isSaving = false;
  String _mapType = "light_all";
  double _currentZoom = 15.0;
  final List<LatLng> _currentPoints = [];
  LatLng? _currentLocation;
  
  final LatLng _center = const LatLng(37.1627, 28.3712);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadFields();
      _updateCurrentLocation(moveMap: false);
    });
  }

  Future<void> _updateCurrentLocation({bool moveMap = true}) async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      final current = LatLng(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() => _currentLocation = current);
      if (moveMap) {
        _mapController.move(current, 16.0);
      }
    } catch (e) {
      debugPrint("Konum hatası: $e");
    }
  }

  void _loadFields() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String email = authProvider.currentUserEmail ?? "test@user.com";
    debugPrint("[FieldsPage._loadFields] fetching for email=$email");
    final fieldsResult = await FieldService.getFields(email);
    
    if (mounted) {
      fieldsResult.fold(
        (error) {
          debugPrint("[FieldsPage._loadFields] failed: $error");
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
        },
        (fields) {
          debugPrint("[FieldsPage._loadFields] success. count=${fields.length}");
          setState(() {
            myFields = fields;
          });
        }
      );
    }
  }

  Future<void> _moveToCurrentLocation() async {
    await _updateCurrentLocation(moveMap: true);
  }

  void _zoomIn() {
    final nextZoom = (_mapController.camera.zoom + 1).clamp(_minZoom, _maxZoom);
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  void _zoomOut() {
    final nextZoom = (_mapController.camera.zoom - 1).clamp(_minZoom, _maxZoom);
    _mapController.move(_mapController.camera.center, nextZoom);
  }

  void _handleTap(TapPosition tapPosition, LatLng point) {
    if (_isDrawing) {
      if (_currentPoints.length >= _maxDrawPoints) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Performans için en fazla 80 nokta ekleyebilirsiniz.")),
        );
        return;
      }
      setState(() {
        _currentPoints.add(point);
      });
    }
  }

  void _toggleMapType() {
    setState(() {
      _mapType = _mapType == "light_all" ? "satellite" : "light_all";
    });
  }

  void _handleMapPositionChanged(MapCamera position, bool hasGesture) {
    final zoom = position.zoom;
    if (zoom != _currentZoom) {
      setState(() {
        _currentZoom = zoom;
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
    String? selectedImageFileName;
    Uint8List? selectedImageBytes;
    bool isPickingImage = false;
    final picker = ImagePicker();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          title: const Text("Tarlayı Kaydet"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    hintText: "Tarla Adı (Örn: Aşağı Zeytinlik)",
                    labelText: "Tarla Adı",
                    prefixIcon: Icon(Icons.label),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.maxFinite,
                  child: OutlinedButton.icon(
                    icon: isPickingImage
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_a_photo_outlined),
                    label: Text(
                      isPickingImage
                          ? "Fotoğraf hazırlanıyor..."
                          : (selectedImageBytes == null ? "Tarla Fotoğrafı Ekle" : "Fotoğrafı Değiştir"),
                    ),
                    onPressed: isPickingImage
                        ? null
                        : () async {
                            debugPrint("[DEBUG] pickImage button pressed. ctx.mounted=${ctx.mounted}");
                            if (!ctx.mounted) return;
                            setDialogState(() => isPickingImage = true);
                            try {
                              debugPrint("[DEBUG] Calling ImagePicker...");
                              final file = await picker.pickImage(
                                source: ImageSource.gallery,
                              );
                              debugPrint("[DEBUG] ImagePicker returned. File selected: ${file != null}");

                              if (!ctx.mounted) {
                                debugPrint("[DEBUG] ctx is not mounted after ImagePicker. Early exiting.");
                                return;
                              }
                              if (file == null) return;

                              final length = await file.length();
                              debugPrint("[DEBUG] File length: $length");
                              if (!ctx.mounted) {
                                debugPrint("[DEBUG] ctx is not mounted after file.length(). Early exiting.");
                                return;
                              }

                              if (length > _maxImageBytes) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Fotoğraf çok büyük. Lütfen daha küçük boyutlu bir görsel seçin (Maks: 4MB)."),
                                  ),
                                );
                                return;
                              }

                              final bytes = await file.readAsBytes();
                              debugPrint("[DEBUG] readAsBytes complete. bytes length: ${bytes.length}");
                              if (!ctx.mounted) return;

                              setDialogState(() {
                                selectedImageBytes = bytes;
                                selectedImageFileName = file.name;
                              });
                              debugPrint("[DEBUG] Image set successfully in dialog state.");
                            } catch (e, stacktrace) {
                              debugPrint("[DEBUG] Error picking image: $e\n$stacktrace");
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text("Fotoğraf seçilemedi: $e")),
                              );
                            } finally {
                              if (ctx.mounted) {
                                setDialogState(() => isPickingImage = false);
                                debugPrint("[DEBUG] finally block: set isPickingImage = false");
                              } else {
                                debugPrint("[DEBUG] finally block: ctx unmounted, cannot reset isPickingImage");
                              }
                            }
                          },
                  ),
                ),
                if (selectedImageBytes != null) ...[
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      selectedImageBytes!,
                      height: 84,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text("Görsel başarıyla seçildi.", style: TextStyle(fontSize: 12, color: Colors.green)),
                ]
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("İptal"),
            ),
            ElevatedButton(
              onPressed: isPickingImage ? null : () {
                Navigator.pop(ctx);
                _saveFieldToBackend(
                  nameController.text,
                  imageBytes: selectedImageBytes,
                  imageFileName: selectedImageFileName,
                );
              },
              child: const Text("Kaydet"),
            ),
          ],
        ),
      ),
    );
  }

  void _saveFieldToBackend(String name, {Uint8List? imageBytes, String? imageFileName}) async {
    if (_isSaving) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    String email = authProvider.currentUserEmail ?? "test@user.com";
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);

    final newField = Field(
      userEmail: email,
      name: name.isEmpty ? "Yeni Tarla ${myFields.length + 1}" : name,
      area: Field.calculateAreaHa(List.from(_currentPoints)),
      points: List.from(_currentPoints),
      crop: null,
      imageUrl: null,
    );

    final result = await FieldService.saveField(newField);

    if (!mounted) return;
    final saveError = result.fold((error) => error, (_) => null);
    if (saveError != null) {
      messenger.showSnackBar(SnackBar(content: Text(saveError), backgroundColor: AppTheme.errorClay));
      setState(() => _isSaving = false);
      return;
    }

    final savedField = result.fold((_) => null, (field) => field);
    if (savedField == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("Tarla kaydedildi ancak cevap okunamadı."), backgroundColor: AppTheme.errorClay),
      );
      setState(() => _isSaving = false);
      return;
    }

    String? uploadedImageUrl;
    if (imageBytes != null) {
      final uploadResult = await FieldService.uploadFieldImage(
        userEmail: email,
        imageBase64: base64Encode(imageBytes),
        fileName: imageFileName ?? "field.jpg",
        fieldId: savedField.id,
      );

      uploadResult.fold(
        (error) {
          messenger.showSnackBar(
            SnackBar(content: Text("Tarla kaydedildi fakat görsel yüklenemedi: $error"), backgroundColor: AppTheme.errorClay),
          );
        },
        (url) {
          uploadedImageUrl = url;
        },
      );
    }

    final finalField = Field(
      id: savedField.id,
      userEmail: savedField.userEmail,
      name: savedField.name,
      area: savedField.area,
      points: savedField.points,
      crop: savedField.crop,
      imageUrl: uploadedImageUrl ?? savedField.imageUrl,
    );

    messenger.showSnackBar(const SnackBar(content: Text("Tarla başarıyla kaydedildi!")));
    setState(() {
      // Optimistic update: immediately reflect the new field in shared in-memory list.
      myFields = [finalField, ...myFields];
      _isDrawing = false;
      _isSaving = false;
      _currentPoints.clear();
    });
    _loadFields();
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
              initialRotation: 0,
              onPositionChanged: _handleMapPositionChanged,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom |
                  InteractiveFlag.drag |
                    InteractiveFlag.doubleTapZoom |
                    InteractiveFlag.scrollWheelZoom,
              ),
              onTap: _handleTap,
            ),
            children: [
              TileLayer(
                urlTemplate: _mapType == "light_all"
                    ? 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}.png'
                    : 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
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
                  );
                }).toList(),
              ),

              if (_currentZoom >= _fieldLabelZoomThreshold)
                MarkerLayer(
                  markers: myFields
                      .where((field) => field.points.length >= 3)
                      .map((field) {
                        return Marker(
                          point: field.center,
                          width: 112,
                          height: 30,
                          child: IgnorePointer(
                            child: Center(
                              child: Text(
                                field.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppTheme.darkGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  shadows: [
                                    Shadow(
                                      color: Colors.white.withValues(alpha: 0.9),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      })
                      .toList(),
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

              if (_currentLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _currentLocation!,
                      width: 26,
                      height: 26,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.blue.withValues(alpha: 0.2),
                        ),
                        child: Center(
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.blue,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
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
            bottom: 270,
            right: 20,
            child: FloatingActionButton(
              heroTag: "zoom_in_btn",
              backgroundColor: AppTheme.surfaceOlive,
              mini: true,
              onPressed: _zoomIn,
              child: const Icon(Icons.add, color: AppTheme.textBlack),
            ),
          ),

          Positioned(
            bottom: 220,
            right: 20,
            child: FloatingActionButton(
              heroTag: "zoom_out_btn",
              backgroundColor: AppTheme.surfaceOlive,
              mini: true,
              onPressed: _zoomOut,
              child: const Icon(Icons.remove, color: AppTheme.textBlack),
            ),
          ),

          Positioned(
            bottom: 170,
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
            bottom: 120,
            right: 20,
            child: FloatingActionButton(
              heroTag: "map_type_btn",
              backgroundColor: AppTheme.surfaceOlive,
              mini: true,
              onPressed: _toggleMapType,
              child: const Icon(Icons.satellite_alt_outlined, color: AppTheme.textBlack),
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
                    onPressed: _isSaving
                        ? null
                        : () => setState(() { _isDrawing = false; _currentPoints.clear(); }),
                    label: const Text("İptal"),
                    icon: const Icon(Icons.close),
                    backgroundColor: AppTheme.surfaceOlive,
                    foregroundColor: AppTheme.errorClay,
                  ),
                  const SizedBox(width: 16),
                  FloatingActionButton.extended(
                    heroTag: "save_btn",
                    onPressed: _isSaving ? null : _showSaveDialog,
                    label: Text(_isSaving ? "Kaydediliyor..." : "Bitir"),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.backgroundGrey,
                            ),
                          )
                        : const Icon(Icons.check),
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