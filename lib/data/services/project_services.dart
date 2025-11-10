import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/project.dart';
import '../models/project_task.dart';

class ProjectService {
  final supabase = Supabase.instance.client;

  Future<List<Project>> fetchProjects() async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('loggedInUserEmail');

    if (userEmail == null) return [];

    try {
      debugPrint('Projeler getiriliyor...');

      // Kullanıcı ID'sini al
      final userResponse = await supabase
          .from('user_profiles')
          .select('id')
          .eq('email', userEmail)
          .single();

      debugPrint('Kullanıcı ID: ${userResponse['id']}');

      // Tüm projeleri al (basit yaklaşım)
      final allProjects = await supabase
          .from('projects')
          .select('*')
          .order('created_at', ascending: false);

      debugPrint('Toplam ${allProjects.length} proje bulundu');

      // Kullanıcının sahip olduğu veya üye olduğu projeleri filtrele
      final userProjects = (allProjects as List).where((project) {
        // Kullanıcının sahip olduğu projeler
        if (project['owner_id'] == userResponse['id']) {
          return true;
        }

        // Kullanıcının üye olduğu projeler (project_members tablosundan kontrol)
        // Bu kısmı daha sonra ekleyeceğiz
        return false;
      }).toList();

      debugPrint('Kullanıcının ${userProjects.length} projesi var');

      return userProjects.map((data) => Project.fromJson(data)).toList();
    } catch (e) {
      debugPrint('Projeler getirilirken hata: $e');
      return [];
    }
  }

  Future<void> addProject(Project project) async {
    final prefs = await SharedPreferences.getInstance();
    final userEmail = prefs.getString('loggedInUserEmail');

    if (userEmail == null) {
      throw Exception('Kullanıcı email bulunamadı');
    }

    try {
      debugPrint('Proje oluşturma başlatılıyor...');
      debugPrint('Kullanıcı email: $userEmail');
      debugPrint('Proje başlığı: ${project.title}');

      // Kullanıcı ID'sini al
      final userResponse = await supabase
          .from('user_profiles')
          .select('id, ad, soyad')
          .eq('email', userEmail)
          .single();

      debugPrint('Kullanıcı ID bulundu: ${userResponse['id']}');

      // Proje verisini hazırla
      final toInsert = {
        'title': project.title,
        'description': project.description ?? '',
        'owner_id': userResponse['id'],
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('Proje verisi: $toInsert');

      // Projeyi oluştur
      final result = await supabase
          .from('projects')
          .insert(toInsert)
          .select()
          .single();

      debugPrint('Proje başarıyla oluşturuldu: ${result['id']}');

      // Proje üyeliği var mı kontrol et
      final existingMember = await supabase
          .from('project_members')
          .select()
          .eq('project_id', result['id'])
          .eq('user_email', userEmail)
          .maybeSingle();

      if (existingMember == null) {
        // Proje oluşturulduktan sonra kullanıcıyı otomatik olarak owner yap
        await supabase.from('project_members').insert({
          'project_id': result['id'],
          'user_email': userEmail,
          'user_name': '${userResponse['ad']} ${userResponse['soyad']}',
          'role': 'owner',
          'status': 'active',
        });

        debugPrint('Proje üyeliği oluşturuldu');
      } else {
        debugPrint('Proje üyeliği zaten mevcut');
      }
    } catch (e) {
      debugPrint('Proje oluşturma hatası: $e');
      debugPrint('Hata detayı: ${e.toString()}');
      rethrow;
    }
  }

  Future<void> deleteProject(String id) async {
    await supabase.from('projects').delete().eq('id', id);
  }

  Future<List<ProjectTask>> getUserProjectTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('loggedInUserEmail');

      if (email == null) return [];

      final response = await supabase
          .from('project_tasks')
          .select('*, projects(title)')
          .eq('assigned_to', email)
          .order('due_datetime', ascending: true);

      return (response as List)
          .map((data) => ProjectTask.fromJson(data))
          .toList();
    } catch (e) {
      return [];
    }
  }
}
