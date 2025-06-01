import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/task.dart';

class TaskService {
  final _client = Supabase.instance.client;

  Future<List<Task>> fetchTasksForCurrentUser() async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumda değil');

    final response = await _client
        .from('tasks')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((e) => Task.fromMap(e)).toList();
  }

  Future<void> updateTask(Task task) async {
    await _client.from('tasks').update({
      'title': task.title,
      'description': task.description,
      'is_done': task.isDone,
    }).eq('id', task.id as Object);
  }

  Future<void> deleteTask(String taskId) async {
    await _client.from('tasks').delete().eq('id', taskId);
  }

  Future<void> insertTask(Task task) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Kullanıcı oturumda değil');

    await _client.from('tasks').insert({
      'title': task.title,
      'description': task.description,
      'is_done': task.isDone,
      'user_id': user.id,
    });
  }
}