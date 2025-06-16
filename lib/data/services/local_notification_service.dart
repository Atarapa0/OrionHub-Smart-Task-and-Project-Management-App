import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:todo_list/data/services/notification_counter_service.dart';

class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  /// Local notifications'ı başlat
  static Future<void> initialize() async {
    try {
      // Timezone'ları başlat
      tz.initializeTimeZones();

      // Android ayarları
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS ayarları
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
            onDidReceiveLocalNotification: _onDidReceiveLocalNotification,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
          );

      await _notifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onNotificationTapped,
      );

      debugPrint('📲 Local Notifications başlatıldı');
    } catch (e) {
      debugPrint('❌ Local Notifications başlatma hatası: $e');
    }
  }

  /// iOS için eski callback (iOS 10 ve altı)
  static void _onDidReceiveLocalNotification(
    int id,
    String? title,
    String? body,
    String? payload,
  ) {
    debugPrint('📱 iOS Local notification alındı: $title');
  }

  /// Notification'a tıklanma işlemi
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🎯 Local notification tapped: ${response.payload}');
    // Burada istediğiniz sayfaya yönlendirme yapabilirsiniz
    // Örnek: Navigator.pushNamed(context, '/notifications');
  }

  /// İzin kontrolü ve isteme
  static Future<bool> requestPermissions() async {
    try {
      // Android 13+ için notification izni
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _notifications
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      if (androidImplementation != null) {
        final bool? granted = await androidImplementation
            .requestNotificationsPermission();
        debugPrint('📱 Android notification izni: $granted');
        return granted ?? false;
      }

      // iOS için izin zaten initialization'da isteniyor
      return true;
    } catch (e) {
      debugPrint('❌ İzin isteme hatası: $e');
      return false;
    }
  }

  /// Anında bildirim göster
  static Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'orionhub_instant',
            'OrionHub Anında Bildirimler',
            channelDescription: 'OrionHub anında bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3), // Blue color
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.show(
        id,
        title,
        body,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('📨 Anında bildirim gönderildi: $title');

      // Bildirim sayacını artır
      NotificationCounterService().incrementUnreadCount();
    } catch (e) {
      debugPrint('❌ Anında bildirim hatası: $e');
    }
  }

  /// Zamanlanmış bildirim göster
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'orionhub_scheduled',
            'OrionHub Zamanlanmış Bildirimler',
            channelDescription: 'OrionHub zamanlanmış bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3),
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );

      debugPrint(
        '⏰ Zamanlanmış bildirim ayarlandı: $title - ${scheduledDate.toString()}',
      );
    } catch (e) {
      debugPrint('❌ Zamanlanmış bildirim hatası: $e');
    }
  }

  /// Periyodik bildirim (günlük, haftalık vb.)
  static Future<void> schedulePeriodicNotification({
    required int id,
    required String title,
    required String body,
    required RepeatInterval repeatInterval,
    String? payload,
  }) async {
    try {
      const AndroidNotificationDetails androidPlatformChannelSpecifics =
          AndroidNotificationDetails(
            'orionhub_periodic',
            'OrionHub Periyodik Bildirimler',
            channelDescription: 'OrionHub periyodik bildirimleri',
            importance: Importance.max,
            priority: Priority.high,
            showWhen: true,
            icon: '@mipmap/ic_launcher',
            color: Color(0xFF2196F3),
          );

      const DarwinNotificationDetails iOSPlatformChannelSpecifics =
          DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          );

      const NotificationDetails platformChannelSpecifics = NotificationDetails(
        android: androidPlatformChannelSpecifics,
        iOS: iOSPlatformChannelSpecifics,
      );

      await _notifications.periodicallyShow(
        id,
        title,
        body,
        repeatInterval,
        platformChannelSpecifics,
        payload: payload,
      );

      debugPrint('🔄 Periyodik bildirim ayarlandı: $title - $repeatInterval');
    } catch (e) {
      debugPrint('❌ Periyodik bildirim hatası: $e');
    }
  }

  /// Görev hatırlatıcısı (görev vadesi yaklaştığında)
  static Future<void> scheduleTaskReminder({
    required int taskId,
    required String taskTitle,
    required DateTime dueDate,
    int minutesBefore = 30, // Varsayılan 30 dakika önce
  }) async {
    final reminderTime = dueDate.subtract(Duration(minutes: minutesBefore));

    // Geçmiş tarih kontrolü
    if (reminderTime.isBefore(DateTime.now())) {
      debugPrint('⚠️ Hatırlatıcı zamanı geçmiş, bildirim ayarlanmadı');
      return;
    }

    await scheduleNotification(
      id: taskId + 10000, // Task ID'sine 10000 ekleyerek unique ID
      title: '⏰ Görev Hatırlatıcısı',
      body: '"$taskTitle" görevi $minutesBefore dakika sonra sona eriyor!',
      scheduledDate: reminderTime,
      payload: 'task_reminder_$taskId',
    );
  }

  /// Günlük özet bildirimi
  static Future<void> scheduleDailySummary({
    required int hour, // 0-23 arası saat
    required int minute, // 0-59 arası dakika
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, hour, minute);

    // Eğer bugünkü saat geçmişse, yarına ayarla
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await scheduleNotification(
      id: 999999, // Unique ID for daily summary
      title: '📊 Günlük Özet',
      body: 'Bugünkü görevlerinizi kontrol etmeyi unutmayın!',
      scheduledDate: scheduledDate,
      payload: 'daily_summary',
    );

    debugPrint(
      '📅 Günlük özet bildirimi ayarlandı: ${scheduledDate.toString()}',
    );
  }

  /// Belirli bir bildirimi iptal et
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
      debugPrint('🚫 Bildirim iptal edildi: $id');
    } catch (e) {
      debugPrint('❌ Bildirim iptal etme hatası: $e');
    }
  }

  /// Tüm bildirimleri iptal et
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
      debugPrint('🚫 Tüm bildirimler iptal edildi');
    } catch (e) {
      debugPrint('❌ Tüm bildirimleri iptal etme hatası: $e');
    }
  }

  /// Bekleyen bildirimleri listele
  static Future<List<PendingNotificationRequest>>
  getPendingNotifications() async {
    try {
      final pendingNotifications = await _notifications
          .pendingNotificationRequests();
      debugPrint('📋 Bekleyen bildirim sayısı: ${pendingNotifications.length}');
      return pendingNotifications;
    } catch (e) {
      debugPrint('❌ Bekleyen bildirimleri alma hatası: $e');
      return [];
    }
  }

  /// Test bildirimi gönder
  static Future<void> sendTestNotification() async {
    await showInstantNotification(
      id: 0,
      title: '🧪 Test Bildirimi',
      body: 'Local notification çalışıyor!',
      payload: 'test_notification',
    );
  }
}
