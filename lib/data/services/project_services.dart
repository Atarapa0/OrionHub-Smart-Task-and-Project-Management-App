import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/project.dart';

class ProjectService {
  final supabase = Supabase.instance.client;

  Future<List<Project>> fetchProjects() async {
    final response = await supabase
        .from('projects')
        .select()
        .order('created_at', ascending: false);

    return (response as List)
        .map((data) => Project.fromJson(data))
        .toList();
  }

  Future<void> addProject(Project project) async {
    final toInsert = {
      'title': project.title,
      'description': project.description,
      'created_by': project.createdBy,
      'created_at': project.createdAt.toIso8601String(),
    };
    await supabase.from('projects').insert(toInsert);
  }

  Future<void> deleteProject(String id) async {
    await supabase.from('projects').delete().eq('id', id);
  }
}