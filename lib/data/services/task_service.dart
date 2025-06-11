import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/utils/navigation_helper.dart';
import '../models/task.dart';

class TaskService {
  final _client = Supabase.instance.client;
  final BuildContext context;

  TaskService(this.context);

  // Kullanıcının giriş yapıp yapmadığını kontrol et (manuel sistem)
  Future<bool> _isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final isManuallyLoggedIn = prefs.getBool('isManuallyLoggedIn') ?? false;
    return isManuallyLoggedIn;
  }

  // Kullanıcı ID'sini al (manuel sistem)
  Future<String?> _getCurrentUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final isManuallyLoggedIn = prefs.getBool('isManuallyLoggedIn') ?? false;

    if (isManuallyLoggedIn) {
      final email = prefs.getString('loggedInUserEmail');
      if (email != null) {
        // Email'den user_profiles tablosundan ID'yi al
        final userProfile = await _client
            .from('user_profiles')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (userProfile != null) {
          debugPrint('Manuel giriş kullanıcısı bulundu: ${userProfile['id']}');
          return userProfile['id'];
        }
      }
    }

    debugPrint('Hiçbir kullanıcı bulunamadı');
    return null;
  }

  Future<List<Task>> fetchTasksForCurrentUser() async {
    final isLoggedIn = await _isUserLoggedIn();
    if (!isLoggedIn) {
      if (context.mounted) {
        NavigationHelper.navigateToLogin(context);
      }
      return [];
    }

    final userId = await _getCurrentUserId();
    if (userId == null) {
      debugPrint('User ID alınamadı');
      return [];
    }

    try {
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => Task.fromMap(e)).toList();
    } catch (e) {
      debugPrint('Task fetch hatası: $e');
      return [];
    }
  }

  Future<void> updateTask(Task task) async {
    await _client
        .from('tasks')
        .update({
          'title': task.title,
          'description': task.description,
          'is_done': task.isDone,
        })
        .eq('id', task.id as Object);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> insertTask(Task task) async {
    final isLoggedIn = await _isUserLoggedIn();
    if (!isLoggedIn) {
      if (context.mounted) {
        NavigationHelper.navigateToLogin(context);
      }
      return;
    }

    final userId = await _getCurrentUserId();
    if (userId == null) {
      debugPrint('User ID alınamadı, task eklenemedi');
      return;
    }

    await _client.from('tasks').insert({
      'title': task.title,
      'description': task.description,
      'is_done': task.isDone,
      'user_id': userId,
    });
  }
}
