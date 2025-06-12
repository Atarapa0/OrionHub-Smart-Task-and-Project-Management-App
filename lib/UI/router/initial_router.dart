import 'package:flutter/material.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/pages/project_detail_page.dart';
import 'package:todo_list/UI/pages/start_page1.dart';
import 'package:todo_list/UI/pages/notifications_page.dart';
import 'package:todo_list/UI/pages/settings_page.dart';
import 'package:todo_list/UI/pages/help_page.dart';
import 'package:todo_list/data/models/project.dart';

class InitialRouter {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());
      case '/start':
        return MaterialPageRoute(builder: (_) => const StartPage());
      case '/project-detail':
        final project = settings.arguments as Project;
        return MaterialPageRoute(
          builder: (_) => ProjectDetailPage(project: project),
        );
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsPage());
      case '/settings':
        return MaterialPageRoute(builder: (_) => const SettingsPage());
      case '/help':
        return MaterialPageRoute(builder: (_) => const HelpPage());
      default:
        return MaterialPageRoute(
          builder: (_) =>
              const Scaffold(body: Center(child: Text('Sayfa bulunamadı'))),
        );
    }
  }
}
