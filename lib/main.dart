import 'package:flutter/material.dart';

import 'package:todo_list/UI/router/initial_router.dart';
import 'package:todo_list/core/config/supabase_config.dart';
import 'package:todo_list/core/services/launch_service.dart';
import 'package:todo_list/UI/pages/start_page1.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/services/local_notification_service.dart';
import 'package:todo_list/data/services/notification_counter_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    debugPrint('🚀 Uygulama başlatılıyor...');

    // Firebase'i başlat (geçici olarak devre dışı)
    debugPrint('⚠️ Firebase geçici olarak devre dışı bırakıldı');

    // Supabase'i başlat
    try {
      await initSupabase();
      debugPrint('✅ Supabase başlatıldı');
    } catch (e) {
      debugPrint('❌ Supabase başlatma hatası: $e');
    }

    // Push notification service (geçici olarak devre dışı)
    debugPrint(
      '⚠️ Push notification service geçici olarak devre dışı bırakıldı',
    );

    try {
      await LocalNotificationService.initialize();
      debugPrint('✅ Local notification service başlatıldı');
    } catch (e) {
      debugPrint('❌ Local notification service hatası: $e');
    }

    try {
      await NotificationCounterService().loadUnreadCount();
      debugPrint('✅ Notification counter service başlatıldı');
    } catch (e) {
      debugPrint('❌ Notification counter service hatası: $e');
    }

    // Launch service ve SharedPreferences
    final isFirstLaunch = await LaunchService.isFirstLaunch();
    final prefs = await SharedPreferences.getInstance();
    final isManuallyLoggedIn = prefs.getBool('isManuallyLoggedIn') ?? false;

    debugPrint('📱 Uygulama başlatma tamamlandı');
    runApp(MyApp(isFirstLaunch: isFirstLaunch, isLoggedIn: isManuallyLoggedIn));
  } catch (e) {
    debugPrint('❌ Kritik hata: $e');
    // Hata olsa bile basit bir uygulama başlat
    runApp(const MyApp(isFirstLaunch: true, isLoggedIn: false));
  }
}

class MyApp extends StatefulWidget {
  final bool isFirstLaunch;
  final bool isLoggedIn;
  const MyApp({
    super.key,
    required this.isFirstLaunch,
    required this.isLoggedIn,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    Widget initialPage;
    if (widget.isFirstLaunch) {
      initialPage = const StartPage();
    } else if (!widget.isLoggedIn) {
      initialPage = const LoginPage();
    } else {
      initialPage = const HomePage();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'OrionHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: initialPage,
      onGenerateRoute: InitialRouter.generateRoute,
    );
  }
}
