import 'package:flutter/material.dart';
import 'package:todo_list/UI/pages/login_page.dart';

class NavigationHelper {
  static void navigateToLogin(BuildContext context) {
    // Build sırasında Navigator kullanımını engellemek için
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    });
  }
}
