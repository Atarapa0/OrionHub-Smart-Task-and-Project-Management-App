import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/router/initial_router.dart';
import 'package:todo_list/core/config/supabase_config.dart';
import 'package:todo_list/core/services/launch_service.dart';
import 'package:todo_list/UI/pages/start_page1.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initSupabase();
    final isFirstLaunch = await LaunchService.isFirstLaunch();

    // Manuel giriş kontrolü
    final prefs = await SharedPreferences.getInstance();
    final isManuallyLoggedIn = prefs.getBool('isManuallyLoggedIn') ?? false;

    runApp(MyApp(isFirstLaunch: isFirstLaunch, isLoggedIn: isManuallyLoggedIn));
  } catch (e) {
    debugPrint('Uygulama başlatılırken hata oluştu: $e');
    rethrow;
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
      title: 'TaskNest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: initialPage,
      onGenerateRoute: InitialRouter.generateRoute,
    );
  }
}
