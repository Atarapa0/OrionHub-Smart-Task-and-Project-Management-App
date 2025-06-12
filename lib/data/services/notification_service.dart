import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:todo_list/data/models/notification.dart';

class NotificationService {
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

  // Kullanıcının bildirimlerini getir
  Future<List<NotificationModel>> getUserNotifications() async {
    try {
      final email = await _getCurrentUserEmail();
      if (email == null) return [];

      final response = await _supabase
          .from('user_notifications')
          .select('*')
          .eq('user_email', email)
          .order('created_at', ascending: false);

      return response.map((json) => NotificationModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Bildirimler getirilirken hata: $e');
      throw Exception('Bildirimler yüklenemedi: $e');
    }
  }

  // Bildirimi okundu olarak işaretle
  Future<void> markAsRead(String notificationId) async {
    try {
      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      debugPrint('Bildirim okundu işaretlenirken hata: $e');
      throw Exception('Bildirim güncellenemedi: $e');
    }
  }

  // Tüm bildirimleri okundu olarak işaretle
  Future<void> markAllAsRead() async {
    try {
      final email = await _getCurrentUserEmail();
      if (email == null) return;

      await _supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_email', email)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Tüm bildirimler okundu işaretlenirken hata: $e');
      throw Exception('Bildirimler güncellenemedi: $e');
    }
  }

  // Proje davetine yanıt ver
  Future<void> respondToProjectInvitation(
    String invitationId,
    bool accept,
  ) async {
    try {
      final email = await _getCurrentUserEmail();
      if (email == null) throw Exception('Kullanıcı bulunamadı');

      // Davet bilgilerini al
      final invitation = await _supabase
          .from('project_invitations')
          .select('*')
          .eq('id', invitationId)
          .single();

      if (invitation['invited_email'] != email) {
        throw Exception('Bu davet size ait değil');
      }

      if (invitation['status'] != 'pending') {
        throw Exception('Bu davet zaten yanıtlanmış');
      }

      // Davet durumunu güncelle
      if (accept) {
        await _supabase
            .from('project_invitations')
            .update({
              'status': 'accepted',
              'responded_at': DateTime.now().toIso8601String(),
            })
            .eq('id', invitationId);
      } else {
        // Reddedilirse davet durumunu güncelle (silme)
        await _supabase
            .from('project_invitations')
            .update({
              'status': 'rejected',
              'responded_at': DateTime.now().toIso8601String(),
            })
            .eq('id', invitationId);
      }

      // Eğer kabul edildiyse, kullanıcıyı proje üyesi olarak ekle
      if (accept) {
        // Önce kullanıcı adını al
        final userProfile = await _supabase
            .from('user_profiles')
            .select('ad, soyad')
            .eq('email', email)
            .single();

        final userName = '${userProfile['ad']} ${userProfile['soyad']}';

        await _supabase.from('project_members').insert({
          'project_id': invitation['project_id'],
          'user_email': email,
          'user_name': userName,
          'role': invitation['role'] ?? 'member',
          'status': 'active',
          'invited_by': invitation['invited_by'],
        });

        // Başarılı katılım bildirimi oluştur
        await _createNotification(
          userEmail: email,
          title: 'Projeye Katıldınız',
          message:
              'Proje davetini kabul ettiniz ve projeye başarıyla katıldınız.',
          type: 'project_added',
          relatedId: invitation['project_id'],
        );
      }

      // Davet bildirimini güncelle (kabul/red durumunu işaretle)
      await _supabase
          .from('notifications')
          .update({
            'action_data': {
              ...invitation,
              'status': accept ? 'accepted' : 'rejected',
              'responded_at': DateTime.now().toIso8601String(),
            },
          })
          .eq('related_id', invitationId)
          .eq('type', 'project_invitation');
    } catch (e) {
      debugPrint('Proje davetine yanıt verilirken hata: $e');
      throw Exception('Davet yanıtlanamadı: $e');
    }
  }

  // Yeni bildirim oluştur
  Future<void> _createNotification({
    required String userEmail,
    required String title,
    required String message,
    required String type,
    String? relatedId,
    Map<String, dynamic>? actionData,
  }) async {
    try {
      debugPrint('📝 Bildirim veritabanına kaydediliyor...');
      debugPrint('   - Email: $userEmail');
      debugPrint('   - Başlık: $title');
      debugPrint('   - Tip: $type');
      debugPrint('   - İlgili ID: $relatedId');

      await _supabase.from('notifications').insert({
        'user_email': userEmail,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'action_data': actionData,
      });

      debugPrint('   ✅ Bildirim veritabanına kaydedildi!');
    } catch (e) {
      debugPrint('❌ Bildirim oluşturulurken hata: $e');
      rethrow;
    }
  }

  // Görev hatırlatma bildirimi oluştur
  Future<void> createTaskReminderNotification({
    required String userEmail,
    required String taskTitle,
    required DateTime dueDateTime,
    required String taskId,
    String? projectTitle,
  }) async {
    final title = projectTitle != null
        ? 'Proje Görevi Hatırlatması: $taskTitle'
        : 'Görev Hatırlatması: $taskTitle';

    final message = projectTitle != null
        ? 'Proje "$projectTitle" içindeki göreviniz "$taskTitle" yakında sona erecek.'
        : 'Göreviniz "$taskTitle" yakında sona erecek.';

    await _createNotification(
      userEmail: userEmail,
      title: title,
      message: message,
      type: 'task_reminder',
      relatedId: taskId,
      actionData: {
        'due_datetime': dueDateTime.toIso8601String(),
        'project_title': projectTitle,
      },
    );
  }

  // Görev atama bildirimi oluştur
  Future<void> createTaskAssignmentNotification({
    required String assignedToEmail,
    required String taskTitle,
    required String projectTitle,
    required String taskId,
    required String projectId,
    required String assignedByName,
  }) async {
    try {
      debugPrint('🔔 Görev atama bildirimi oluşturuluyor...');
      debugPrint('   - Atanan: $assignedToEmail');
      debugPrint('   - Görev: $taskTitle');
      debugPrint('   - Proje: $projectTitle');
      debugPrint('   - Atayan: $assignedByName');
      debugPrint('   - Görev ID: $taskId');

      // Bu spesifik görev için zaten atama bildirimi var mı kontrol et
      final existingNotification = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_email', assignedToEmail)
          .eq('type', 'task_assigned')
          .eq('related_id', taskId)
          .maybeSingle();

      debugPrint(
        '   - Mevcut bildirim kontrolü: ${existingNotification != null ? "VAR" : "YOK"}',
      );

      if (existingNotification == null) {
        debugPrint('   ✅ Yeni bildirim oluşturuluyor...');
        await _createNotification(
          userEmail: assignedToEmail,
          title: 'Yeni Proje Görevi Atandı',
          message:
              '$assignedByName tarafından "$projectTitle" projesinde size "$taskTitle" görevi atandı.',
          type: 'task_assigned',
          relatedId: taskId,
          actionData: {
            'project_id': projectId,
            'project_title': projectTitle,
            'task_title': taskTitle,
            'assigned_by': assignedByName,
          },
        );
        debugPrint('   ✅ Bildirim başarıyla oluşturuldu!');
      } else {
        debugPrint(
          '   ⚠️ Bu görev için zaten bildirim var (ID: ${existingNotification['id']}), atlanıyor',
        );
      }
    } catch (e) {
      debugPrint('❌ Görev atama bildirimi oluşturulurken hata: $e');
    }
  }

  // Okunmamış bildirim sayısını getir
  Future<int> getUnreadNotificationCount() async {
    try {
      final email = await _getCurrentUserEmail();
      if (email == null) return 0;

      final response = await _supabase
          .from('notifications')
          .select('id')
          .eq('user_email', email)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Okunmamış bildirim sayısı alınırken hata: $e');
      return 0;
    }
  }

  // Eski bildirimleri temizle
  Future<void> cleanupOldNotifications() async {
    try {
      await _supabase.rpc('cleanup_old_notifications');
    } catch (e) {
      debugPrint('Eski bildirimler temizlenirken hata: $e');
    }
  }

  // Kabul/red edilen davet bildirimlerini 1 gün sonra temizle
  Future<void> cleanupAcceptedInvitations() async {
    try {
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));

      // 1 gün önce kabul edilen davetleri sil (sadece project_invitations tablosundan)
      await _supabase
          .from('project_invitations')
          .delete()
          .eq('status', 'accepted')
          .lt('responded_at', oneDayAgo.toIso8601String());

      // Kabul/red edilen davet bildirimlerini 1 gün sonra temizle
      // Önce kabul/red edilen davetlerin ID'lerini al
      final respondedInvitations = await _supabase
          .from('project_invitations')
          .select('id')
          .neq('status', 'pending')
          .lt('responded_at', oneDayAgo.toIso8601String());

      if (respondedInvitations.isNotEmpty) {
        final invitationIds = respondedInvitations
            .map((inv) => inv['id'] as String)
            .toList();

        // Bu davetlere ait bildirimleri sil
        await _supabase
            .from('notifications')
            .delete()
            .eq('type', 'project_invitation')
            .inFilter('related_id', invitationIds);

        debugPrint('Kabul/red edilen eski davet bildirimleri temizlendi');
      }

      debugPrint('Kabul edilen eski davetler temizlendi');
    } catch (e) {
      debugPrint('Kabul edilen davetler temizlenirken hata: $e');
    }
  }

  // Proje görev bildirimleri oluştur
  Future<void> createProjectTaskNotifications() async {
    try {
      final email = await _getCurrentUserEmail();
      if (email == null) return;

      // Kullanıcının proje görevlerini al
      final response = await _supabase
          .from('project_tasks')
          .select('''
            *,
            projects!inner(
              title
            )
          ''')
          .eq('assigned_to', email)
          .neq('status', 'done');

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (final taskData in response) {
        final taskId = taskData['id'];
        final taskTitle = taskData['title'];
        final projectTitle = taskData['projects']['title'];
        final projectId = taskData['project_id'];
        final dueDateTime = taskData['due_datetime'] != null
            ? DateTime.parse(taskData['due_datetime'])
            : null;

        // Son gün bildirimi kontrolü
        if (dueDateTime != null) {
          final dueDate = DateTime(
            dueDateTime.year,
            dueDateTime.month,
            dueDateTime.day,
          );

          // Bugün son gün mü?
          if (dueDate.isAtSameMomentAs(today)) {
            // Bu görev için bugün bildirim var mı kontrol et
            final existingNotification = await _supabase
                .from('notifications')
                .select('id')
                .eq('user_email', email)
                .eq('type', 'task_due_soon')
                .eq('related_id', taskId)
                .gte('created_at', today.toIso8601String())
                .maybeSingle();

            if (existingNotification == null) {
              // Son gün bildirimi oluştur
              await _createNotification(
                userEmail: email,
                title: 'Proje Görevi Son Gün!',
                message:
                    '"$projectTitle" projesindeki "$taskTitle" görevinizin son günü!',
                type: 'task_due_soon',
                relatedId: taskId,
                actionData: {
                  'project_id': projectId,
                  'project_title': projectTitle,
                  'task_title': taskTitle,
                  'due_datetime': dueDateTime.toIso8601String(),
                },
              );
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Proje görev bildirimleri oluşturulurken hata: $e');
    }
  }
}
