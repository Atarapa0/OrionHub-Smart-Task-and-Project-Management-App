import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _adController = TextEditingController();
  final TextEditingController _soyadController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _telefonController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _registerUser() async {
    final supabase = Supabase.instance.client;

    final res = await supabase.auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    final user = res.user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kayıt başarısız')),
      );
      return;
    }

    await supabase.from('profiles').insert({
      'id': user.id,
      'ad': _adController.text.trim(),
      'soyad': _soyadController.text.trim(),
      'telefon': _telefonController.text.trim(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kayıt başarılı!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kayıt Ol')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _adController, decoration: const InputDecoration(labelText: 'Ad')),
            TextField(controller: _soyadController, decoration: const InputDecoration(labelText: 'Soyad')),
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _telefonController, decoration: const InputDecoration(labelText: 'Telefon')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerUser,
              child: const Text('Kayıt Ol'),
            ),
          ],
        ),
      ),
    );
  }
}