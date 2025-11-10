import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/pages/notifications_page.dart';
import 'package:todo_list/data/services/notification_counter_service.dart';
import 'package:todo_list/data/services/push_notification_service.dart';
import 'package:todo_list/UI/widget/notification_badge.dart';

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(70);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String _userName = '';

  final NotificationCounterService _counterService =
      NotificationCounterService();
  bool _isNavigatingToNotifications = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _loadUserName();
    _loadNotificationCount();

    // Stream'i dinle (NotificationBadge widget'ı kendi sayacını yönetiyor)
    _counterService.notificationCountStream.listen((count) {
      // NotificationBadge widget'ı otomatik güncelleniyor
      debugPrint('🔔 Bildirim sayısı güncellendi: $count');
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userName = prefs.getString('loggedInUserName') ?? 'Kullanıcı';
      if (mounted) {
        setState(() {
          _userName = userName;
        });
      }
    } catch (e) {
      debugPrint('Kullanıcı adı yüklenirken hata: $e');
    }
  }

  Future<void> _loadNotificationCount() async {
    try {
      await _counterService.loadUnreadCount();
      debugPrint(
        '📊 Bildirim sayısı yüklendi: ${_counterService.notificationCount}',
      );
    } catch (e) {
      debugPrint('Bildirim sayısı yüklenirken hata: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    // Animasyon başlat
    _animationController.forward();

    try {
      // Shared Preferences'dan manuel giriş durumunu temizle
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isManuallyLoggedIn');
      await prefs.remove('loggedInUserEmail');
      await prefs.remove('loggedInUserName');

      // Supabase Auth'dan da çıkış yap (eğer varsa)
      try {
        await Supabase.instance.client.auth.signOut();
      } catch (e) {
        debugPrint('Supabase Auth çıkış hatası (normal): $e');
      }

      if (!context.mounted) return;

      // Login sayfasına yönlendir ve tüm stack'i temizle
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (Route<dynamic> route) => false,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Text('Başarıyla çıkış yapıldı'),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 8),
              Text('Çıkış yapılırken hata oluştu'),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } finally {
      // Animasyonu geri al
      _animationController.reverse();
    }
  }

  void _showUserMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue.shade100,
                    child: Text(
                      _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _userName.isNotEmpty ? _userName : 'Kullanıcı',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ListTile(
                    leading: Icon(Icons.logout, color: Colors.red.shade600),
                    title: const Text('Çıkış Yap'),
                    onTap: () {
                      Navigator.pop(context);
                      _logout(context);
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.blue.shade600, Colors.purple.shade600],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(26),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        toolbarHeight: 70,
        title: GestureDetector(
          onTap: () {
            // Mevcut widget'ı kontrol et - HomePage'de miyiz?
            final currentWidget = context.widget;
            debugPrint(
              'Logo tıklandı - Widget türü: ${currentWidget.runtimeType}',
            );

            // Eğer mevcut sayfa HomePage ise hiçbir şey yapma
            bool isOnHomePage = false;
            context.visitAncestorElements((element) {
              if (element.widget.runtimeType.toString().contains('HomePage')) {
                isOnHomePage = true;
                return false; // Aramayı durdur
              }
              return true; // Aramaya devam et
            });

            if (isOnHomePage) {
              debugPrint('Zaten HomePage\'de, işlem iptal edildi');
              return;
            }

            debugPrint('Ana sayfaya yönlendiriliyor...');
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (Route<dynamic> route) => false,
            );
          },
          onLongPress: () async {
            // Test bildirimi gönder (gizli özellik)
            await PushNotificationService.sendTestNotification();
            _counterService.incrementNotificationCount();

            if (mounted && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🔔 Test bildirimi gönderildi!'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.asset(
                    'assets/OrionHub_appbar_logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OrionHub',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Görev Yöneticisi',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: [
          // Bildirim butonu
          Container(
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: NotificationBadge(
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              onPressed: () async {
                // Static flag ile kontrol et
                if (NotificationsPage.isCurrentlyActive) {
                  debugPrint('NotificationsPage aktif, işlem iptal edildi');
                  return;
                }

                // Eğer zaten navigasyon işlemi devam ediyorsa engelle
                if (_isNavigatingToNotifications) {
                  debugPrint(
                    'Zaten navigasyon işlemi devam ediyor, işlem iptal edildi',
                  );
                  return;
                }

                // Mevcut route'u kontrol et
                final currentRoute = ModalRoute.of(context)?.settings.name;
                debugPrint('Bildirim butonuna basıldı - Route: $currentRoute');

                // Eğer zaten bildirimler sayfasındaysa hiçbir şey yapma
                if (currentRoute == '/notifications') {
                  debugPrint(
                    'Route kontrolü: Zaten bildirimler sayfasında, işlem iptal edildi',
                  );
                  return;
                }

                // Navigasyon flag'ini set et
                setState(() {
                  _isNavigatingToNotifications = true;
                });

                try {
                  debugPrint('Bildirimler sayfasına gidiliyor...');

                  // Bildirim sayacını sıfırla
                  await _counterService.clearUnreadCount();

                  if (mounted && context.mounted) {
                    await Navigator.pushNamed(context, '/notifications');
                  }

                  // Bildirimler sayfasına gidince sayıyı güncelle
                  await Future.delayed(const Duration(milliseconds: 500));
                  _loadNotificationCount();
                } finally {
                  // Flag'i temizle
                  if (mounted) {
                    setState(() {
                      _isNavigatingToNotifications = false;
                    });
                  }
                }
              },
            ),
          ),
          // Kullanıcı profil butonu
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: GestureDetector(
                onTap: () => _showUserMenu(context),
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withAlpha(51),
                  child: Text(
                    _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
