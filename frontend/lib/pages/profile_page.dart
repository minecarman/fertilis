import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text("Profil", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: AppTheme.surfaceOlive,
        foregroundColor: AppTheme.wikilocGreen,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profil Kartı
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.surfaceOlive,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkGreen.withValues(alpha: 0.08),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: AppTheme.surfaceMoss),
            ),
            child: Column(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundColor: AppTheme.backgroundGrey,
                  child: Icon(Icons.person, color: AppTheme.wikilocGreen, size: 50),
                ),
                const SizedBox(height: 16),
                Text(
                  authProvider.currentUserName ?? (authProvider.currentUserEmail != null 
                      ? authProvider.currentUserEmail!.split('@').first.toUpperCase() 
                      : "Kullanıcı"),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textBlack),
                ),
                const SizedBox(height: 4),
                Text(
                  authProvider.currentUserEmail ?? "kullanici@fertilis.com",
                  style: const TextStyle(fontSize: 15, color: AppTheme.textGrey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.pushNamed('edit-profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.wikilocGreen,
                    foregroundColor: AppTheme.backgroundGrey,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Profili Düzenle"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          // Ayarlar Seçenekleri
          const Text("Ayarlar", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceOlive,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.darkGreen.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                )
              ],
              border: Border.all(color: AppTheme.surfaceMoss),
            ),
            child: Column(
              children: [
                _buildListTile(Icons.settings_outlined, "Uygulama Ayarları", () {}),
                const Divider(height: 1, indent: 16, endIndent: 16),
                _buildListTile(
                  Icons.logout, 
                  "Çıkış Yap", 
                  () {
                    Provider.of<AuthProvider>(context, listen: false).logout();
                    context.goNamed('login');
                  }, 
                  color: AppTheme.errorClay
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(IconData icon, String title, VoidCallback onTap, {Color color = AppTheme.textBlack}) {
    return ListTile(
      leading: Icon(icon, color: color == AppTheme.errorClay ? AppTheme.errorClay : AppTheme.wikilocGreen),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppTheme.textGrey),
      onTap: onTap,
    );
  }
}
