import 'package:flutter/material.dart';
import 'package:todo_list/UI/pages/home_page.dart';
import 'package:todo_list/UI/pages/profile_page.dart';
import 'package:todo_list/UI/pages/project_page.dart';

class BottomNavigationController extends StatelessWidget {
  const BottomNavigationController({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home Page'),
        BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Project'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
      onTap: (index) {
        switch (index) {
          case 0:
            if (index == 0 && index != 1 && index != 2) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const HomePage()));
            }
            break;
          case 1:
            if (index != 0 && index != 2 && index == 1) {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProjectPage()));
            }
            break;
          case 2:
            if (index != 0 && index != 1 && index == 2) {
              // Eğer kullanıcı profil sayfasına gitmek istiyorsa
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
            }
            break;
        }
      },
    );
  }
}