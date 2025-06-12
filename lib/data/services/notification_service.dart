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
      await _supabase
          .from('project_invitations')
          .update({
            'status': accept ? 'accepted' : 'rejected',
            'responded_at': DateTime.now().toIso8601String(),
          })
          .eq('id', invitationId);

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

      // İlgili bildirimi güncelle
      await _supabase
          .from('notifications')
          .update({
            'action_data': {
              ...invitation,
              'status': accept ? 'accepted' : 'rejected',
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
      await _supabase.from('notifications').insert({
        'user_email': userEmail,
        'title': title,
        'message': message,
        'type': type,
        'related_id': relatedId,
        'action_data': actionData,
      });
    } catch (e) {
      debugPrint('Bildirim oluşturulurken hata: $e');
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
    required String userEmail,
    required String taskTitle,
    required String projectTitle,
    required String assignedBy,
    required String taskId,
    required String projectId,
  }) async {
    await _createNotification(
      userEmail: userEmail,
      title: 'Yeni Görev Atandı: $taskTitle',
      message:
          '$assignedBy tarafından "$projectTitle" projesinde size "$taskTitle" görevi atandı.',
      type: 'task_assigned',
      relatedId: taskId,
      actionData: {
        'project_id': projectId,
        'project_title': projectTitle,
        'assigned_by': assignedBy,
      },
    );
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
}
