import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';

class ProjectPage extends StatefulWidget {
  const ProjectPage({super.key});

  @override
  State<ProjectPage> createState() => _ProjectPageState();
}

class _ProjectPageState extends State<ProjectPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Stack(
        children: [
          Center(
            child: Text(
              'Project Page',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const BottomNavigationController(),
    );
  }
}
