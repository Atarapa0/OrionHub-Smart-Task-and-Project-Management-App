import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/router/initial_router.dart';
import 'package:todo_list/core/config/supabase_config.dart';
import 'package:todo_list/core/services/launch_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initSupabase();
    final isFirstLaunch = await LaunchService.isFirstLaunch();
    final session =  Supabase.instance.client.auth.currentSession;
    final isLoggedIn = session?.user != null;
    
    runApp(MyApp(isFirstLaunch: isFirstLaunch, isLoggedIn: isLoggedIn));
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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskNest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: InitialRouter(
        isFirstLaunch: widget.isFirstLaunch,
        isLoggedIn: widget.isLoggedIn,
      ),
    );
  }
}
