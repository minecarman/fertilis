import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:fpdart/fpdart.dart' hide State;
import '../models/field.dart';
import '../core/theme.dart';
import 'fields_page.dart';
import 'chat_page.dart';
import 'weather_page.dart';
import 'irrigation_page.dart';
import 'recommendation_page.dart';
import '../models/weather.dart';
import '../services/weather_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardView(),
    const FieldsPage(),
    const ChatPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            )
          ],
        ),
        child: NavigationBar(
          backgroundColor: Colors.white,
          elevation: 0,
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) => setState(() => _currentIndex = index),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppTheme.darkGreen),
              label: 'Özet',
            ),
            NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map, color: AppTheme.darkGreen),
              label: 'Tarlalar',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble, color: AppTheme.darkGreen),
              label: 'Asistan',
            ),
          ],
        ),
      ),
    );
  }
}


class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  Field? activeField;

  @override
  void initState() {
    super.initState();
    if (myFields.isNotEmpty) {
      activeField = myFields.first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text("Fertilis", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.wikilocGreen,
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none), onPressed: () {}),
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: GestureDetector(
              onTap: () {
                context.pushNamed('profile');
              },
              child: const CircleAvatar(
                radius: 16,
                backgroundColor: AppTheme.backgroundGrey,
                child: Icon(Icons.person, color: AppTheme.wikilocGreen, size: 20),
              ),
            ),
          ),
        ],
      ),
      body: myFields.isEmpty ? _buildEmptyState() : _buildContent(),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Şu Anki Durum",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBlack),
            ),
            
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<Field>(
                  value: activeField,
                  isDense: true,
                  icon: const Icon(Icons.keyboard_arrow_down, color: AppTheme.wikilocGreen),
                  style: const TextStyle(color: AppTheme.textBlack, fontWeight: FontWeight.w600),
                  items: myFields.map((f) => DropdownMenuItem(value: f, child: Text(f.name))).toList(),
                  onChanged: (val) => setState(() => activeField = val),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),

        if (activeField != null) _buildMainFieldCard(activeField!),

        const SizedBox(height: 24),
        const Text("Araçlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
        const SizedBox(height: 12),

        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.1,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildActionCard(
              icon: Icons.water_drop,
              color: Colors.blue,
              title: "Sulama Analizi",
              onTap: () {
                if (activeField != null) {
                  _showToolModal(context, "Sulama Asistanı", IrrigationPage(field: activeField!));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce bir tarla seçin")));
                }
              },
            ),
            _buildActionCard(
              icon: Icons.grass,
              color: Colors.green,
              title: "Ekin Önerisi",
              onTap: () {
                if (activeField != null) {
                  _showToolModal(context, "Ekin Önerisi", RecommendationPage(field: activeField!));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce bir tarla seçin")));
                }
              },
            ),
            _buildActionCard(
              icon: Icons.cloud,
              color: Colors.orange,
              title: "Hava Durumu",
              onTap: () {
                if (activeField != null) {
                  _showToolModal(context, "Detaylı Hava Durumu", WeatherPage(field: activeField!));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Lütfen önce bir tarla seçin")));
                }
              },
            ),
             _buildActionCard(
              icon: Icons.currency_lira,
              color: Colors.purple,
              title: "Kazanç Hesapla",
              onTap: () {},
            ),
          ],
        ),
      ],
    );
  }


  void _showToolModal(BuildContext context, String title, Widget childWidget) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85, 
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  ),
                ],
              ),
            ),
            const Divider(),
            
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: childWidget, 
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainFieldCard(Field field) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // --- GÖRSEL ALANI ---
          Stack(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: Image.network(
                  "https://picsum.photos/seed/fertilis/800/400",
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Container(height: 160, color: Colors.grey.shade100);
                  },
                  errorBuilder: (c, e, s) => Container(
                    height: 160, 
                    color: AppTheme.wikilocGreen.withValues(alpha: 0.1),
                    child: const Center(child: Icon(Icons.landscape, size: 40, color: Colors.grey)),
                  ),
                ),
              ),
              Positioned(
                top: 12, left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.white, size: 14),
                      SizedBox(width: 4),
                      Text("Konum Kayıtlı", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(field.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
                const SizedBox(height: 16),
                
                FutureBuilder<Either<String, Weather>>(
                  future: WeatherService.getWeather(field.center.latitude, field.center.longitude),
                  builder: (context, snapshot) {
                    
                    // 1. Durum: Yükleniyor
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.wikilocGreen)
                        )
                      );
                    }

                    if (snapshot.hasError || !snapshot.hasData) {
                      return const Text("Hava durumu verisi alınamadı.", style: TextStyle(color: Colors.grey));
                    }

                    return snapshot.data!.fold(
                      (error) => const Text("Hava durumu verisi alınamadı.", style: TextStyle(color: Colors.grey)),
                      (weather) {
                        final temp = weather.temp.toString();
                        final humidity = weather.humidity.toString();
                        
                        String desc = weather.description;
                        if (desc.length > 1) {
                          desc = desc[0].toUpperCase() + desc.substring(1);
                        }
                        if (desc.length > 10) { 
                          desc = "${desc.substring(0, 10)}..."; // Çok uzunsa kes
                        }

                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(Icons.thermostat, "$temp°C", "Sıcaklık"),
                            Container(height: 30, width: 1, color: Colors.grey.shade300),
                            _buildStatItem(Icons.water_drop_outlined, "%$humidity", "Nem"),
                            Container(height: 30, width: 1, color: Colors.grey.shade300),
                            _buildStatItem(Icons.wb_sunny_outlined, desc, "Durum"),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({required IconData icon, required Color color, required String title, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textBlack),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.wikilocGreen, size: 24),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textBlack)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textGrey)),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ],
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.wikilocGreen.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.eco_rounded, size: 48, color: AppTheme.wikilocGreen),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Hoş Geldiniz!",
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textBlack),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Henüz bir tarlanız bulunmuyor. Başlamak için şu adımları izleyebilirsiniz:",
                    style: TextStyle(fontSize: 15, color: AppTheme.textGrey, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  _buildTutorialStep(Icons.touch_app_outlined, "Aşağıdaki menüden 'Tarlalar' sekmesine gidin."),
                  const SizedBox(height: 16),
                  _buildTutorialStep(Icons.add_location_alt_outlined, "Harita üzerinden tarlanızı oluşturun ve detaylarını girin."),
                  const SizedBox(height: 16),
                  _buildTutorialStep(Icons.dashboard_customize_outlined, "Analiz ve hava durumu verilerini bu sayfadan takip edin."),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialStep(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppTheme.wikilocGreen, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: AppTheme.textBlack, height: 1.4),
          ),
        ),
      ],
    );
  }
}