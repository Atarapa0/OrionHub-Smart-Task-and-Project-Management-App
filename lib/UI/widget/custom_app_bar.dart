import 'package:flutter/material.dart';
import 'package:todo_list/core/consants/color_file.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
         automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.menu), // Sol tarafta menü butonu
          onPressed: () {
            // Menü sayfasına gitme işlemi
          },
        ),
        title: Text('TaskNest'),
        backgroundColor: ColorFile.backgroundColor,
        actions: [
          IconButton(
            icon: Icon(Icons.settings), // Sağ tarafta ayarlar butonu
            onPressed: () {
              // Ayarlar sayfasına gitme işlemi
            },
          ),
        ],
      );
  }
}