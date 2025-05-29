import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:todo_list/UI/pages/register_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  Future<void> _loginUser() async {
    final supabase = Supabase.instance.client;

    final res = await supabase.auth.signInWithPassword(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    final user = res.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Giriş başarısız')),
      );
      return;
    }

    final profile = await supabase
        .from('profiles')
        .select()
        .eq('id', user.id)
        .single();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hoşgeldin ${profile['ad']}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Giriş Yap')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Şifre'), obscureText: true),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginUser,
              child: const Text('Giriş Yap'),
            ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegisterPage()),
                  );
                },
                child: const Text('Hesabın yok mu? Kayıt ol'),
              ),
            
            
          ],
        ),
      ),
    );
  }
}