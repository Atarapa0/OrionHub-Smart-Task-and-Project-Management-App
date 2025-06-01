import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text;
    if (newPassword.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lütfen yeni şifre girin.')),
      );
      return;
    }

    try {
      final response = await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;

      if (response.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Şifre başarıyla güncellendi.')),
        );
        _passwordController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Şifre güncellenemedi: ${response.error!.message}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bir hata oluştu: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Builder(
              builder: (context) {
                final user = Supabase.instance.client.auth.currentUser;
                String displayName = 'Kullanıcı adı bulunamadı';
                if (user != null) {
                  final meta = user.userMetadata;
                  final firstName = meta != null && meta['first_name'] != null && meta['first_name'].toString().isNotEmpty
                      ? meta['first_name'].toString()
                      : null;
                  final lastName = meta != null && meta['last_name'] != null && meta['last_name'].toString().isNotEmpty
                      ? meta['last_name'].toString()
                      : null;
                  if (firstName != null && lastName != null) {
                    displayName = '$firstName $lastName';
                  } else if (firstName != null) {
                    displayName = firstName;
                  } else if (lastName != null) {
                    displayName = lastName;
                  }
                }
                return Row(
                  children: [
                    const Icon(Icons.person),
                    const SizedBox(width: 10),
                    Text(displayName),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.email),
                SizedBox(width: 10),
                Text('Email: john.doe@example.com'),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: const [
                Icon(Icons.phone),
                SizedBox(width: 10),
                Text('Phone: +1 234 567 8900'),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _updatePassword,
              child: const Text('Şifreyi Güncelle'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const BottomNavigationController(),
    );
  }
}

extension on UserResponse {
  get error => null;
}