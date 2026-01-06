import 'package:flutter/material.dart';
import '../services/irrigation_service.dart';
import '../models/field.dart';
import 'fields_page.dart';

class IrrigationPage extends StatefulWidget {
  const IrrigationPage({super.key});

  @override
  State<IrrigationPage> createState() => _IrrigationPageState();
}

class _IrrigationPageState extends State<IrrigationPage> {
  Field? _selectedField;
  bool loading = false;
  Map<String, dynamic>? result;

  Future<void> analyze() async {
    if (_selectedField == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen tarla seçiniz")));
      return;
    }

    setState(() {
      loading = true;
      result = null;
    });

    final data = await IrrigationService.analyzeRain(
      _selectedField!.center.latitude, 
      _selectedField!.center.longitude
    );

    setState(() {
      result = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue),
                SizedBox(width: 12),
                Expanded(child: Text("FAO-56 standardına göre, tarlanızın konumundaki buharlaşma verisi hesaplanır.")),
              ],
            ),
          ),
          
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hangi tarlayı sulayacaksın?", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Field>(
                      isExpanded: true,
                      value: _selectedField,
                      hint: const Text("Tarla Seçiniz"),
                      items: myFields.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                      onChanged: (val) => setState(() => _selectedField = val),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: loading ? null : analyze,
                    icon: const Icon(Icons.water_drop),
                    label: const Text("Analiz Et"),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          if (loading) const CircularProgressIndicator(),
          
          if (result != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: result!["decision"].toString().contains("gerek yok") ? Colors.green.shade50 : Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: result!["decision"].toString().contains("gerek yok") ? Colors.green : Colors.orange),
              ),
              child: Column(
                children: [
                  Text("Tahmini Yağış: ${result!["rain"]} mm", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("${result!["decision"]}", textAlign: TextAlign.center),
                ],
              ),
            )
        ],
      ),
    );
  }
}