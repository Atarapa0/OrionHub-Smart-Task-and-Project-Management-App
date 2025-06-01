import 'package:flutter/material.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:todo_list/UI/pages/login_page.dart';
import 'package:todo_list/UI/pages/start_page1.dart';

class InitialRouter extends StatelessWidget {
  final bool isFirstLaunch;
  final bool isLoggedIn;

  const InitialRouter({super.key, required this.isFirstLaunch, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    if (isFirstLaunch) return const StartPage();
    if (!isLoggedIn) return const LoginPage();
    return const HomePage();
  }
}