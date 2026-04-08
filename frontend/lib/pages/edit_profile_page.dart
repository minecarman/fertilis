import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../core/theme.dart';
import '../services/auth_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: authProvider.currentUserName ?? "");
    _emailController = TextEditingController(text: authProvider.currentUserEmail ?? "");
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isLoading = true);
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    
    final authResult = await AuthService.updateProfile(
      authProvider.currentUserEmail!,
      _emailController.text.trim(),
      _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    
    authResult.fold(
      (errorMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      },
      (user) {
        authProvider.setUser(
          user.email.isNotEmpty ? user.email : _emailController.text.trim(),
          user.fullName.isNotEmpty ? user.fullName : _nameController.text.trim(),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil güncellendi.", style: TextStyle(color: Colors.white)), backgroundColor: Colors.green),
        );
        
        if (context.canPop()) {
          context.pop();
        } else {
          context.goNamed('profile');
        }
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundGrey,
      appBar: AppBar(
        title: const Text("Profili Düzenle", style: TextStyle(fontWeight: FontWeight.w800)),
        backgroundColor: Colors.white,
        foregroundColor: AppTheme.wikilocGreen,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Ad Soyad", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: "Adınızı girin",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.person_outline, color: AppTheme.wikilocGreen),
                ),
                validator: (value) => value == null || value.isEmpty ? "Lütfen adınızı girin" : null,
              ),
              
              const SizedBox(height: 20),
              const Text("E-posta", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textBlack)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: "E-posta adresiniz",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.email_outlined, color: AppTheme.wikilocGreen),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return "E-posta zorunludur";
                  if (!value.contains('@')) return "Geçerli bir e-posta girin";
                  return null;
                },
              ),
              
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.wikilocGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text("Kaydet", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
