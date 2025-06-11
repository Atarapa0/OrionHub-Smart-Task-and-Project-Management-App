import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  bool _isLoading = false;
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _adController = TextEditingController();
  final _soyadController = TextEditingController();
  final _telefonController = TextEditingController();

  @override
  void dispose() {
    _adController.dispose();
    _soyadController.dispose();
    _emailController.dispose();
    _telefonController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Manuel kayıt yöntemi - Ana kayıt sistemi
  Future<void> _registerUser() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final supabase = Supabase.instance.client;

    try {
      setState(() => _isLoading = true);

      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final ad = _adController.text.trim();
      final soyad = _soyadController.text.trim();
      final telefon = _telefonController.text.trim();

      debugPrint('Manuel kayıt işlemi başlatılıyor: $email');

      // Önce email'in zaten kayıtlı olup olmadığını kontrol et
      final existingUsers = await supabase
          .from('user_profiles')
          .select('email')
          .eq('email', email)
          .limit(1);

      if (existingUsers.isNotEmpty) {
        throw Exception('Bu email adresi zaten kayıtlı');
      }

      // Şifreyi hash'le
      final bytes = utf8.encode(password);
      final hashedPassword = sha256.convert(bytes).toString();

      // Kullanıcıyı manuel olarak user_profiles tablosuna kaydet
      final response = await supabase.from('user_profiles').insert({
        'email': email,
        'password_hash': hashedPassword,
        'ad': ad,
        'soyad': soyad,
        'telefon': telefon.isEmpty ? null : telefon,
        'created_at': DateTime.now().toIso8601String(),
        'is_verified': false,
      }).select();

      debugPrint('Manuel kayıt başarılı: $response');

      // İsteğe bağlı: Supabase Auth'a da kayıt yapmayı dene (sessizce)
      try {
        debugPrint('Supabase Auth\'a da kayıt deneniyor...');
        final authResponse = await supabase.auth.signUp(
          email: email,
          password: password,
          data: {
            'first_name': ad,
            'last_name': soyad,
            'phone': telefon.isEmpty ? null : telefon,
            'full_name': '$ad $soyad',
          },
        );

        if (authResponse.user != null) {
          debugPrint(
            'Supabase Auth\'a da başarıyla kaydedildi: ${authResponse.user!.id}',
          );
        }
      } catch (authError) {
        debugPrint('Supabase Auth kayıt hatası (önemli değil): $authError');
        // Bu hata önemli değil, manuel kayıt başarılı oldu
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kayıt başarılı! Şimdi giriş yapabilirsiniz.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      debugPrint('Manuel kayıt hatası: $e');
      if (!mounted) return;

      String errorMessage = 'Kayıt işlemi başarısız oldu.';
      if (e.toString().contains('zaten kayıtlı')) {
        errorMessage = 'Bu email adresi zaten kayıtlı';
      } else if (e.toString().contains('duplicate key')) {
        errorMessage = 'Bu email adresi zaten kullanılıyor';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              TextFormField(
                controller: _adController,
                decoration: const InputDecoration(
                  labelText: 'Ad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen adınızı girin';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _soyadController,
                decoration: const InputDecoration(
                  labelText: 'Soyad',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen soyadınızı girin';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen email adresinizi girin';
                  }
                  if (!RegExp(
                    r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                  ).hasMatch(value)) {
                    return 'Lütfen geçerli bir email adresi girin';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _telefonController,
                decoration: const InputDecoration(
                  labelText: 'Telefon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
                keyboardType: TextInputType.phone,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Şifre',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen şifrenizi girin';
                  }
                  if (value.length < 6) {
                    return 'Şifre en az 6 karakter olmalıdır';
                  }
                  return null;
                },
                enabled: !_isLoading,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _registerUser,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Kayıt Ol', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
