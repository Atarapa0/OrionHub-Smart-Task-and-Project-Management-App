import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registerUser() async {
    final supabase = Supabase.instance.client;
    
    try {
      // Kullanıcı bilgilerini kontrol et
      if (_emailController.text.isEmpty || 
          _passwordController.text.isEmpty ||
          _adController.text.isEmpty ||
          _soyadController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen tüm alanları doldurun')),
        );
        return;
      }

      // Önce auth kaydı oluştur
      final res = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = res.user;
      if (user == null) {
        throw Exception('Kullanıcı kaydı oluşturulamadı');
      }

      // Sonra profil bilgilerini kaydet
      await supabase.from('profiles').upsert({
        'id': user.id,
        'ad': _adController.text.trim(),
        'soyad': _soyadController.text.trim(),
        'telefon': _telefonController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarılı!')),
      );
      
      Navigator.pop(context); // Başarılı kayıttan sonra login sayfasına dön
      
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kayıt hatası: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(controller: _soyadController, decoration: const InputDecoration(labelText: 'Soyad')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}