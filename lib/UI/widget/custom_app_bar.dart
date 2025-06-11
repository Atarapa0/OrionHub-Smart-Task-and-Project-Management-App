import 'package:flutter/material.dart';
import 'package:todo_list/core/consants/color_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/pages/login_page.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Future<void> _logout(BuildContext context) async {
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
        const SnackBar(
          content: Text('Başarıyla çıkış yapıldı'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint('Çıkış hatası: $e');
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Çıkış yapılırken hata oluştu'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      automaticallyImplyLeading: false,
      leading: IconButton(
        icon: const Icon(Icons.menu), // Sol tarafta menü butonu
        onPressed: () {
          // Menü sayfasına gitme işlemi
        },
      ),
      title: const Text('TaskNest'),
      backgroundColor: ColorFile.backgroundColor,
      actions: [
        IconButton(
          icon: const Icon(Icons.settings), // Ayarlar butonu
          onPressed: () {
            // Ayarlar sayfasına gitme işlemi
          },
        ),
        IconButton(
          icon: const Icon(Icons.logout), // Çıkış butonu
          onPressed: () => _logout(context),
          tooltip: 'Çıkış Yap',
        ),
      ],
    );
  }
}
