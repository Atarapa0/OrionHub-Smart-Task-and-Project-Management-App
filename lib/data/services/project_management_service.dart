import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/models/project_member.dart';
import 'package:todo_list/data/models/project_task.dart';
import 'dart:math';

class ProjectManagementService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Mevcut kullanıcının email'ini al
  Future<String?> _getCurrentUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('loggedInUserEmail');
    } catch (e) {
      debugPrint('Kullanıcı email alınırken hata: $e');
      return null;
    }
  }

  // Kullanıcı email'ini Supabase context'ine set et
  Future<void> _setUserContext() async {
    final email = await _getCurrentUserEmail();
    if (email != null) {
      await _supabase.rpc(
        'set_config',
        params: {
          'setting_name': 'app.current_user_email',
          'setting_value': email,
        },
      );
    }
  }

  // PROJE ÜYELERİ YÖNETİMİ

  // Proje üyelerini getir
  Future<List<ProjectMember>> getProjectMembers(String projectId) async {
    try {
      await _setUserContext();

      final response = await _supabase
          .from('project_members')
          .select('*')
          .eq('project_id', projectId)
          .eq('status', 'active')
          .order('joined_at');

      return response.map((json) => ProjectMember.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Proje üyeleri getirilirken hata: $e');
      throw Exception('Proje üyeleri yüklenemedi: $e');
    }
  }

  // Kullanıcının proje rolünü kontrol et
  Future<String?> getUserRoleInProject(String projectId) async {
    try {
      await _setUserContext();
      final email = await _getCurrentUserEmail();
      if (email == null) return null;

      final response = await _supabase
          .from('project_members')
          .select('role')
          .eq('project_id', projectId)
          .eq('user_email', email)
          .eq('status', 'active')
          .maybeSingle();

      return response?['role'];
    } catch (e) {
      debugPrint('Kullanıcı rolü kontrol edilirken hata: $e');
      return null;
    }
  }

  // Kayıtlı kullanıcıları ara (email ile)
  Future<List<Map<String, dynamic>>> searchRegisteredUsers(String query) async {
    try {
      if (query.length < 2) return [];

      final response = await _supabase
          .from('user_profiles')
          .select('email, ad, soyad')
          .or('email.ilike.%$query%,ad.ilike.%$query%,soyad.ilike.%$query%')
          .limit(10);

      return response
          .map(
            (user) => {
              'email': user['email'],
              'name': '${user['ad']} ${user['soyad']}',
              'ad': user['ad'],
              'soyad': user['soyad'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Kullanıcı arama hatası: $e');
      return [];
    }
  }

  // Projeye üye ekle (direkt ekleme)
  Future<bool> addMemberToProject({
    required String projectId,
    required String userEmail,
    required String userName,
    String role = 'member',
  }) async {
    try {
      await _setUserContext();
      final currentUserEmail = await _getCurrentUserEmail();

      await _supabase.from('project_members').insert({
        'project_id': projectId,
        'user_email': userEmail,
        'user_name': userName,
        'role': role,
        'status': 'active',
        'invited_by': currentUserEmail,
      });

      return true;
    } catch (e) {
      debugPrint('Üye ekleme hatası: $e');
      throw Exception('Üye eklenemedi: $e');
    }
  }

  // Üye rolünü güncelle
  Future<bool> updateMemberRole(String memberId, String newRole) async {
    try {
      await _setUserContext();

      await _supabase
          .from('project_members')
          .update({'role': newRole})
          .eq('id', memberId);

      return true;
    } catch (e) {
      debugPrint('Üye rolü güncelleme hatası: $e');
      throw Exception('Üye rolü güncellenemedi: $e');
    }
  }

  // Üyeyi projeden çıkar
  Future<bool> removeMemberFromProject(String memberId) async {
    try {
      await _setUserContext();

      await _supabase
          .from('project_members')
          .update({'status': 'removed'})
          .eq('id', memberId);

      return true;
    } catch (e) {
      debugPrint('Üye çıkarma hatası: $e');
      throw Exception('Üye çıkarılamadı: $e');
    }
  }

  // PROJE GÖREVLERİ YÖNETİMİ

  // Proje görevlerini getir
  Future<List<ProjectTask>> getProjectTasks(String projectId) async {
    try {
      await _setUserContext();

      final response = await _supabase
          .from('project_tasks')
          .select('*')
          .eq('project_id', projectId)
          .order('created_at', ascending: false);

      return response.map((json) => ProjectTask.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Proje görevleri getirilirken hata: $e');
      throw Exception('Proje görevleri yüklenemedi: $e');
    }
  }

  // Yeni görev ekle
  Future<bool> addProjectTask(ProjectTask task) async {
    try {
      await _setUserContext();
      final currentUserEmail = await _getCurrentUserEmail();

      final taskData = task.toJson();
      taskData['assigned_by'] = currentUserEmail;
      taskData.remove('id'); // ID'yi kaldır, otomatik oluşturulsun

      await _supabase.from('project_tasks').insert(taskData);
      return true;
    } catch (e) {
      debugPrint('Görev ekleme hatası: $e');
      throw Exception('Görev eklenemedi: $e');
    }
  }

  // Görev durumunu güncelle
  Future<bool> updateTaskStatus(String taskId, String newStatus) async {
    try {
      await _setUserContext();

      await _supabase
          .from('project_tasks')
          .update({'status': newStatus})
          .eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Görev durumu güncelleme hatası: $e');
      throw Exception('Görev durumu güncellenemedi: $e');
    }
  }

  // Görev atamasını güncelle
  Future<bool> assignTask(String taskId, String? assignedToEmail) async {
    try {
      await _setUserContext();

      await _supabase
          .from('project_tasks')
          .update({'assigned_to': assignedToEmail})
          .eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Görev atama hatası: $e');
      throw Exception('Görev atanamadı: $e');
    }
  }

  // Görevi sil
  Future<bool> deleteProjectTask(String taskId) async {
    try {
      await _setUserContext();

      await _supabase.from('project_tasks').delete().eq('id', taskId);

      return true;
    } catch (e) {
      debugPrint('Görev silme hatası: $e');
      throw Exception('Görev silinemedi: $e');
    }
  }

  // DAVET YÖNETİMİ

  // Davet gönder
  Future<String> sendProjectInvitation({
    required String projectId,
    required String invitedEmail,
  }) async {
    try {
      await _setUserContext();
      final currentUserEmail = await _getCurrentUserEmail();

      // Davet token'ı oluştur
      final token = _generateInvitationToken();

      await _supabase.from('project_invitations').insert({
        'project_id': projectId,
        'invited_email': invitedEmail,
        'invited_by': currentUserEmail,
        'invitation_token': token,
        'status': 'pending',
      });

      return token;
    } catch (e) {
      debugPrint('Davet gönderme hatası: $e');
      throw Exception('Davet gönderilemedi: $e');
    }
  }

  // Davet token'ı oluştur
  String _generateInvitationToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        32,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  // Daveti kabul et
  Future<Map<String, dynamic>> acceptInvitation(String token) async {
    try {
      final response = await _supabase.rpc(
        'accept_project_invitation',
        params: {'invitation_token_param': token},
      );

      return Map<String, dynamic>.from(response);
    } catch (e) {
      debugPrint('Davet kabul etme hatası: $e');
      throw Exception('Davet kabul edilemedi: $e');
    }
  }

  // Kullanıcının projelerini getir
  Future<List<Map<String, dynamic>>> getUserProjects() async {
    try {
      await _setUserContext();
      final email = await _getCurrentUserEmail();
      if (email == null) return [];

      final response = await _supabase
          .from('project_members')
          .select('''
            project_id,
            role,
            joined_at,
            projects!inner(
              id,
              title,
              description,
              created_at
            )
          ''')
          .eq('user_email', email)
          .eq('status', 'active');

      return response
          .map(
            (item) => {
              'project_id': item['project_id'],
              'role': item['role'],
              'joined_at': item['joined_at'],
              'project': item['projects'],
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Kullanıcı projeleri getirilirken hata: $e');
      return [];
    }
  }

  // Proje istatistiklerini getir
  Future<Map<String, dynamic>> getProjectStats(String projectId) async {
    try {
      await _setUserContext();

      // Görev istatistikleri
      final tasks = await getProjectTasks(projectId);
      final members = await getProjectMembers(projectId);

      final totalTasks = tasks.length;
      final completedTasks = tasks.where((t) => t.isCompleted).length;
      final inProgressTasks = tasks.where((t) => t.isInProgress).length;
      final todoTasks = tasks.where((t) => t.isTodo).length;

      final highPriorityTasks = tasks.where((t) => t.isHighPriority).length;
      final overdueTasks = tasks
          .where(
            (t) =>
                t.dueDate != null &&
                t.dueDate!.isBefore(DateTime.now()) &&
                !t.isCompleted,
          )
          .length;

      return {
        'total_tasks': totalTasks,
        'completed_tasks': completedTasks,
        'in_progress_tasks': inProgressTasks,
        'todo_tasks': todoTasks,
        'high_priority_tasks': highPriorityTasks,
        'overdue_tasks': overdueTasks,
        'total_members': members.length,
        'completion_rate': totalTasks > 0
            ? (completedTasks / totalTasks * 100).round()
            : 0,
      };
    } catch (e) {
      debugPrint('Proje istatistikleri getirilirken hata: $e');
      return {};
    }
  }
}
