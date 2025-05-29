import 'package:flutter/material.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:todo_list/UI/pages/start_page1.dart';
import 'package:todo_list/core/config/supabase_config.dart';
import 'package:todo_list/core/services/launch_service.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await initSupabase();
    final isFirstLaunch = await LaunchService.isFirstLaunch();
    runApp(MyApp(isFirstLaunch: isFirstLaunch));
  } catch (e) {
    print('Uygulama başlatılırken hata oluştu: $e');
    rethrow;
  }
}

class MyApp extends StatefulWidget {
  final bool isFirstLaunch;
  const MyApp({super.key, required this.isFirstLaunch});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'TaskNest',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: widget.isFirstLaunch ? const StartPage() : const HomePage(),
    );
  }
}