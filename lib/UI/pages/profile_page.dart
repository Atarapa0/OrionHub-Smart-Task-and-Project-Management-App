import 'package:flutter/material.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  // Kullanıcı bilgilerini yükle (manuel sistem)
  Future<void> _loadUserInfo() async {
    try {
      setState(() => _isLoading = true);

      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();

      // Manuel giriş kontrol et
      final isManuallyLoggedIn = prefs.getBool('isManuallyLoggedIn') ?? false;
      if (isManuallyLoggedIn) {
        final email = prefs.getString('loggedInUserEmail');
        if (email != null) {
          // User profiles tablosundan bilgileri al
          final userProfile = await supabase
              .from('user_profiles')
              .select('*')
              .eq('email', email)
              .maybeSingle();

          if (userProfile != null) {
            _userInfo = {
              'email': userProfile['email'] ?? 'Email bulunamadı',
              'ad': userProfile['ad'] ?? 'Ad bulunamadı',
              'soyad': userProfile['soyad'] ?? 'Soyad bulunamadı',
              'telefon': userProfile['telefon'] ?? 'Telefon bulunamadı',
              'full_name':
                  '${userProfile['ad'] ?? ''} ${userProfile['soyad'] ?? ''}',
              'auth_type': 'manual',
              'created_at': userProfile['created_at'],
              'is_verified': userProfile['is_verified'],
            };
          }
        }
      }

      if (_userInfo == null) {
        _userInfo = {
          'email': 'Kullanıcı bulunamadı',
          'ad': 'Ad bulunamadı',
          'soyad': 'Soyad bulunamadı',
          'telefon': 'Telefon bulunamadı',
          'full_name': 'Kullanıcı bulunamadı',
          'auth_type': 'unknown',
        };
      }
    } catch (e) {
      debugPrint('Kullanıcı bilgileri yüklenirken hata: $e');
      _userInfo = {
        'email': 'Hata oluştu',
        'ad': 'Hata oluştu',
        'soyad': 'Hata oluştu',
        'telefon': 'Hata oluştu',
        'full_name': 'Hata oluştu',
        'auth_type': 'error',
      };
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı Bilgileri Kartı
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kullanıcı Bilgileri',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.blue),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Ad Soyad',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _userInfo?['full_name'] ?? 'Bilinmiyor',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.email, color: Colors.green),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _userInfo?['email'] ?? 'Bilinmiyor',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.phone, color: Colors.orange),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Telefon',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    Text(
                                      _userInfo?['telefon'] ?? 'Belirtilmemiş',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.storage, color: Colors.teal),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Hesap Türü',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const Text(
                                      'Manuel Kayıt',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Çıkış Yap Butonu
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);

                        try {
                          // Manuel giriş bilgilerini temizle
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('isManuallyLoggedIn');
                          await prefs.remove('loggedInUserEmail');
                          await prefs.remove('loggedInUserName');

                          if (!mounted) return;

                          navigator.pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const LoginPage(),
                            ),
                            (route) => false,
                          );
                        } catch (e) {
                          if (!mounted) return;
                          scaffoldMessenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                'Çıkış yapılırken hata oluştu: ${e.toString()}',
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Çıkış Yap',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavigationController(),
    );
  }
}
