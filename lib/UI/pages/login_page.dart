import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:todo_list/UI/pages/register_page.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // Manuel giriş yöntemi (user_profiles tablosu kullanarak)
  Future<void> _loginUserManually() async {
    final supabase = Supabase.instance.client;
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    // Şifreyi hash'le
    final bytes = utf8.encode(password);
    final hashedPassword = sha256.convert(bytes).toString();

    // user_profiles tablosundan kullanıcıyı bul
    final userProfile = await supabase
        .from('user_profiles')
        .select()
        .eq('email', email)
        .eq('password_hash', hashedPassword)
        .maybeSingle();

    if (userProfile == null) {
      throw Exception('Email veya şifre hatalı');
    }

    debugPrint('Manuel giriş başarılı: ${userProfile['email']}');

    // Giriş durumunu kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isManuallyLoggedIn', true);
    await prefs.setString('loggedInUserEmail', userProfile['email']);
    await prefs.setString(
      'loggedInUserName',
      '${userProfile['ad']} ${userProfile['soyad']}',
    );

    debugPrint('SharedPreferences kaydedildi');

    if (!mounted) return;

    debugPrint('Navigation başlatılıyor...');

    // Başarı mesajını göster
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Hoşgeldin ${userProfile['ad']} ${userProfile['soyad']}'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 1),
      ),
    );

    // Loading state'i hemen kapat
    setState(() => _isLoading = false);

    // Kısa gecikme sonrası navigation
    await Future.delayed(const Duration(milliseconds: 300));

    if (!mounted) {
      debugPrint('Widget mounted değil, navigation iptal edildi');
      return;
    }

    debugPrint('Ana sayfaya yönlendiriliyor...');

    // Tüm navigation stack'i temizle ve ana sayfaya git
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const HomePage()),
      (Route<dynamic> route) => false,
    );

    debugPrint('Navigation tamamlandı');
  }

  Future<void> _loginUser() async {
      if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lütfen email ve şifre giriniz')),
        );
        return;
      }

    setState(() => _isLoading = true);
    bool loginSuccessful = false;

    try {
      // Önce manuel giriş sistemini dene (çünkü kullanıcılar manuel kayıt oldu)
      try {
        await _loginUserManually();
        // Manuel giriş başarılı olursa burada çık
        loginSuccessful = true;
        return;
      } catch (manualError) {
        debugPrint(
          'Manuel giriş başarısız, Supabase Auth deneniyor: $manualError',
        );

        // Manuel giriş başarısız olursa Supabase Auth dene
      final supabase = Supabase.instance.client;

        try {
      final res = await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      final user = res.user;
      if (user == null) {
        throw Exception('Giriş başarısız');
      }

          debugPrint('Supabase Auth giriş başarılı: ${user.email}');

          // Profil bilgilerini kontrol et
      try {
        final profile = await supabase
            .from('profiles')
            .select()
            .eq('id', user.id)
            .maybeSingle();

        if (profile == null) {
          // Profil bulunamadı, yeni profil oluştur
          await supabase.from('profiles').insert({
            'id': user.id,
            'ad': 'Kullanıcı',
            'updated_at': DateTime.now().toIso8601String(),
          });
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Hoşgeldin ${profile?['ad'] ?? 'Kullanıcı'}'),
              ),
        );
        
        Navigator.pushReplacement(
          context, 
              MaterialPageRoute(builder: (context) => const HomePage()),
        );
            loginSuccessful = true;
            return;
      } catch (e) {
        debugPrint('Profil hatası: $e');
        if (!mounted) return;
        
        Navigator.pushReplacement(
          context, 
              MaterialPageRoute(builder: (context) => const HomePage()),
        );
            loginSuccessful = true;
            return;
          }
        } on AuthException catch (e) {
          debugPrint('Supabase Auth hatası: ${e.message}');
          throw Exception('Email veya şifre hatalı');
        }
      }
    } catch (e) {
      debugPrint('Giriş hatası: $e');
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email veya şifre hatalı'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      // Sadece giriş başarısız olduğunda loading state'i kapat
      if (mounted && !loginSuccessful) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.email),
              ),
              keyboardType: TextInputType.emailAddress,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'Şifre',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
              enabled: !_isLoading,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _loginUser,
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
                    : const Text('Giriş Yap', style: TextStyle(fontSize: 16)),
              ),
            ),
              const SizedBox(height: 20),
              TextButton(
              onPressed: _isLoading
                  ? null
                  : () {
                  Navigator.push(
                    context,
                        MaterialPageRoute(
                          builder: (context) => const RegisterPage(),
                        ),
                  );
                },
                child: const Text('Hesabın yok mu? Kayıt ol'),
              ),
          ],
        ),
      ),
    );
  }
}
