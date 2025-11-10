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
    // Önce auth.uid() kontrol et
    final authUser = _client.auth.currentUser;
    if (authUser != null) {
      debugPrint('Auth kullanıcısı bulundu: ${authUser.id}');
      return authUser.id;
    }

    // Manuel giriş kontrolü
    final prefs = await SharedPreferences.getInstance();
    final isManuallyLoggedIn = prefs.getBool('isManuallyLoggedIn') ?? false;

    if (isManuallyLoggedIn) {
      final email = prefs.getString('loggedInUserEmail');
      if (email != null) {
        // Email'den user_profiles tablosundan ID'yi al
        final profile = await _client
            .from('user_profiles')
            .select('id')
            .eq('email', email)
            .maybeSingle();

        if (profile != null) {
          debugPrint('Manuel giriş kullanıcısı bulundu: ${profile['id']}');
          return profile['id'];
        }
      }
    }

    debugPrint('Hiçbir kullanıcı bulunamadı');
    return null;
  }

  Future<List<Task>> fetchTasksForCurrentUser() async {
    debugPrint('🔄 fetchTasksForCurrentUser çağrıldı');

    final isLoggedIn = await _isUserLoggedIn();
    if (!isLoggedIn) {
      debugPrint('❌ Kullanıcı giriş yapmamış');
      if (context.mounted) {
        NavigationHelper.navigateToLogin(context);
      }
      return [];
    }

    final userId = await _getCurrentUserId();
    if (userId == null) {
      debugPrint('❌ User ID alınamadı');
      return [];
    }

    try {
      debugPrint('📡 Supabase\'den görevler çekiliyor - User ID: $userId');
      final response = await _client
          .from('tasks')
          .select()
          .eq('user_id', userId)
          .order('due_datetime', ascending: true) // Tarihe göre sırala
          .order(
            'created_at',
            ascending: false,
          ); // Sonra oluşturulma tarihine göre

      final tasks = (response as List).map((e) => Task.fromMap(e)).toList();
      debugPrint('✅ ${tasks.length} görev bulundu');

      // Görev başlıklarını da yazdır
      for (var task in tasks) {
        debugPrint('   - ${task.title} (ID: ${task.id}) - ${task.timeStatus}');
      }

      return tasks;
    } catch (e) {
      debugPrint('❌ Task fetch hatası: $e');
      return [];
    }
  }

  Future<void> updateTask(Task task) async {
    try {
      await _client
          .from('tasks')
          .update({
            'title': task.title,
            'description': task.description,
            'status': task.status,
            'priority': task.priority,
            'category': task.category,
            'due_date': task.dueDate?.toIso8601String().split('T')[0],
            'due_time': task.dueTime,
          })
          .eq('id', task.id as Object);

      debugPrint('✅ Görev güncellendi: ${task.title}');
    } catch (e) {
      debugPrint('❌ Görev güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _client
          .from('tasks')
          .update({'status': newStatus})
          .eq('id', taskId);

      debugPrint('✅ Görev durumu güncellendi: $taskId -> $newStatus');
    } catch (e) {
      debugPrint('❌ Görev durum güncelleme hatası: $e');
      rethrow;
    }
  }

  Future<void> deleteTask(dynamic taskId) async {
    try {
      debugPrint('🗑️ Görev silme işlemi başlıyor - ID: $taskId');

      // Önce görevin var olup olmadığını kontrol et
      final existingTask = await _client
          .from('tasks')
          .select('id, title, user_id')
          .eq('id', taskId.toString())
          .maybeSingle();

      if (existingTask == null) {
        debugPrint('❌ Görev bulunamadı - ID: $taskId');
        return;
      }

      debugPrint('✅ Görev bulundu: ${existingTask['title']}');

      // Mevcut kullanıcı ID'sini al
      final currentUserId = await _getCurrentUserId();
      if (currentUserId == null) {
        debugPrint('❌ Kullanıcı ID alınamadı');
        throw Exception('Kullanıcı kimliği doğrulanamadı');
      }

      // Kullanıcı kontrolü
      if (existingTask['user_id'] != currentUserId) {
        debugPrint('❌ Yetki hatası: Görev başka kullanıcıya ait');
        throw Exception('Bu görevi silme yetkiniz yok');
      }

      // Silme işlemi (RLS devre dışı olduğu için artık çalışmalı)
      await _client.from('tasks').delete().eq('id', taskId.toString());

      debugPrint('✅ Görev başarıyla silindi');
    } catch (e) {
      debugPrint('❌ Görev silme hatası: $e');
      rethrow;
    }
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

    try {
      await _client.from('tasks').insert({
        'title': task.title,
        'description': task.description,
        'status': task.status,
        'priority': task.priority,
        'category': task.category,
        'due_date': task.dueDate?.toIso8601String().split('T')[0],
        'due_time': task.dueTime,
        'user_id': userId,
      });

      debugPrint('✅ Yeni görev eklendi: ${task.title}');
    } catch (e) {
      debugPrint('❌ Görev ekleme hatası: $e');
      rethrow;
    }
  }

  // Öncelik bazında görevleri getir
  Future<List<Task>> getTasksByPriority(String priority) async {
    final allTasks = await fetchTasksForCurrentUser();
    return allTasks.where((task) => task.priority == priority).toList();
  }

  // Durum bazında görevleri getir
  Future<List<Task>> getTasksByStatus(String status) async {
    final allTasks = await fetchTasksForCurrentUser();
    return allTasks.where((task) => task.status == status).toList();
  }

  // Bugün bitiş tarihi olan görevleri getir
  Future<List<Task>> getTodayTasks() async {
    final allTasks = await fetchTasksForCurrentUser();
    final today = DateTime.now();

    return allTasks.where((task) {
      if (task.dueDate == null) return false;
      return task.dueDate!.year == today.year &&
          task.dueDate!.month == today.month &&
          task.dueDate!.day == today.day;
    }).toList();
  }

  // Süresi geçmiş görevleri getir
  Future<List<Task>> getOverdueTasks() async {
    final allTasks = await fetchTasksForCurrentUser();
    final now = DateTime.now();

    return allTasks.where((task) {
      if (task.dueDateTime == null) return false;
      return task.dueDateTime!.isBefore(now) && task.status != 'completed';
    }).toList();
  }
}
