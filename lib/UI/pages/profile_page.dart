import 'package:flutter/material.dart';
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

      _userInfo ??= {
        'email': 'Kullanıcı bulunamadı',
        'ad': 'Ad bulunamadı',
        'soyad': 'Soyad bulunamadı',
        'telefon': 'Telefon bulunamadı',
        'full_name': 'Kullanıcı bulunamadı',
        'auth_type': 'unknown',
      };
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kullanıcı Bilgileri Kartı
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.blue.shade100,
                                child: Text(
                                  (_userInfo?['full_name'] ?? 'U')
                                      .split(' ')
                                      .map(
                                        (name) =>
                                            name.isNotEmpty ? name[0] : '',
                                      )
                                      .join('')
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userInfo?['full_name'] ?? 'Bilinmiyor',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _userInfo?['email'] ?? 'Bilinmiyor',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          const Divider(),
                          const SizedBox(height: 16),
                          _buildInfoRow(
                            Icons.phone,
                            'Telefon',
                            _userInfo?['telefon'] ?? 'Belirtilmemiş',
                            Colors.orange,
                          ),
                          const SizedBox(height: 12),
                          _buildInfoRow(
                            Icons.storage,
                            'Hesap Türü',
                            'Manuel Kayıt',
                            Colors.teal,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Menü Seçenekleri
                  Text(
                    'Menü',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Bildirimler
                  _buildMenuCard(
                    icon: Icons.notifications,
                    title: 'Bildirimler',
                    subtitle: 'Görev hatırlatmaları ve proje davetleri',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(context, '/notifications');
                    },
                  ),
                  const SizedBox(height: 12),

                  // Ayarlar
                  _buildMenuCard(
                    icon: Icons.settings,
                    title: 'Ayarlar',
                    subtitle: 'Şifre değiştirme ve hesap ayarları',
                    color: Colors.grey,
                    onTap: () {
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const SizedBox(height: 12),

                  // Yardım
                  _buildMenuCard(
                    icon: Icons.help,
                    title: 'Yardım',
                    subtitle: 'Uygulama kullanımı ve SSS',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pushNamed(context, '/help');
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
      bottomNavigationBar: const BottomNavigationController(initialIndex: 2),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: Colors.grey.shade400,
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}
