import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../models/field.dart';
import '../pages/fields_page.dart';
import '../services/field_service.dart';
import '../core/theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Future<void> _editField(Field field) async {
    final fieldId = int.tryParse(field.id ?? "");
    if (fieldId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarla düzenlenemedi. Geçersiz tarla ID.")),
        );
      }
      return;
    }

    final nameController = TextEditingController(text: field.name);

    final updatedName = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tarla adı düzenle"),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(labelText: "Tarla Adı"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, nameController.text),
            child: const Text("Kaydet"),
          ),
        ],
      ),
    );

    if (updatedName == null) return;

    final result = await FieldService.updateFieldName(fieldId: fieldId, name: updatedName);
    if (!mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.errorClay),
        );
      },
      (updatedField) {
        setState(() {
          final index = myFields.indexWhere((item) => item.id == updatedField.id);
          if (index != -1) {
            myFields[index] = updatedField;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarla adı güncellendi.")),
        );
      },
    );
  }

  Future<void> _deleteField(Field field) async {
    final fieldId = int.tryParse(field.id ?? "");
    if (fieldId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarla silinemedi. Geçersiz tarla ID.")),
        );
      }
      return;
    }

    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Tarla sil"),
        content: Text("${field.name} tarlasını silmek istediğinize emin misiniz?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Sil"),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    final result = await FieldService.deleteField(fieldId);
    if (!mounted) return;

    result.fold(
      (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: AppTheme.errorClay),
        );
      },
      (_) {
        setState(() {
          myFields.removeWhere((item) => item.id == field.id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tarla silindi.")),
        );
      },
    );
  }

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
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
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
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Provider.of<AuthProvider>(context, listen: false).logout();
                          context.goNamed('login');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.errorClay,
                          foregroundColor: AppTheme.backgroundGrey,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text("Çıkış Yap"),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Tarlalarım
          const Text("Tarlalarım", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
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
            child: myFields.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Henüz kayıtlı tarla yok.", style: TextStyle(color: AppTheme.textBlack)),
                  )
                : Column(
                    children: myFields.map((field) {
                      return Column(
                        children: [
                          ListTile(
                            leading: const Icon(Icons.landscape_outlined, color: AppTheme.wikilocGreen),
                            title: Text(field.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text("${field.calculatedArea.toStringAsFixed(1)} ha"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppTheme.wikilocGreen),
                                  onPressed: () => _editField(field),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: AppTheme.errorClay),
                                  onPressed: () => _deleteField(field),
                                ),
                              ],
                            ),
                          ),
                          if (field != myFields.last)
                            const Divider(height: 1, indent: 16, endIndent: 16),
                        ],
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
