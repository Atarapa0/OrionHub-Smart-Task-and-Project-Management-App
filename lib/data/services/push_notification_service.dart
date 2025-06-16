import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:todo_list/data/services/local_notification_service.dart';
import 'package:todo_list/data/services/notification_counter_service.dart';

/// Background message handler (top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('🔔 Background mesaj alındı: ${message.notification?.title}');

  // Background'da da sayacı artır
  await NotificationCounterService().loadUnreadCount();
  await NotificationCounterService().incrementUnreadCount();
}

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  // Singleton pattern
  static final PushNotificationService _instance =
      PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  /// Push notification'ları ayarla
  static Future<void> initialize() async {
    try {
      // Background message handler'ı kaydet
      FirebaseMessaging.onBackgroundMessage(
        _firebaseMessagingBackgroundHandler,
      );

      // Notification izinlerini iste
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );

      debugPrint(
        '📱 Notification izin durumu: ${settings.authorizationStatus}',
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('✅ Push notification izni verildi');

        // FCM token'ını al
        String? token = await _firebaseMessaging.getToken();
        debugPrint('🔑 FCM Token: $token');

        // Token değişikliklerini dinle
        _firebaseMessaging.onTokenRefresh.listen((newToken) {
          debugPrint('🔄 FCM Token yenilendi: $newToken');
        });

        // Local notifications'ı başlat
        await _initializeLocalNotifications();

        // Message handler'ları ayarla
        _setupMessageHandlers();
      } else {
        debugPrint('❌ Push notification izni reddedildi');
      }
    } catch (e) {
      debugPrint('❌ Push notification başlatma hatası: $e');
    }
  }

  /// Local notifications'ı başlat
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    debugPrint('📲 Local notifications başlatıldı');
  }

  /// Message handler'ları ayarla
  static void _setupMessageHandlers() {
    // Uygulama açıkken gelen mesajlar
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('📨 Foreground mesaj alındı: ${message.notification?.title}');
      _showLocalNotification(message);
      // Bildirim sayacını artır
      NotificationCounterService().incrementUnreadCount();
    });

    // Uygulama arka plandayken notification'a tıklanma
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('🔔 Notification tıklandı: ${message.notification?.title}');
      _handleNotificationTap(message);
      // Bildirim sayacını artır
      NotificationCounterService().incrementUnreadCount();
    });

    // Uygulama kapalıyken notification'a tıklanma
    _firebaseMessaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        debugPrint(
          '🚀 Uygulama notification ile açıldı: ${message.notification?.title}',
        );
        _handleNotificationTap(message);
      }
    });
  }

  /// Local notification göster
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    // LocalNotificationService kullanarak göster
    await LocalNotificationService.showInstantNotification(
      id: message.hashCode,
      title: message.notification?.title ?? 'OrionHub',
      body: message.notification?.body ?? 'Yeni bildirim',
      payload: message.data.toString(),
    );

    debugPrint(
      '📱 Foreground bildirim gösterildi: ${message.notification?.title}',
    );
  }

  /// Notification'a tıklanma işlemi
  static void _handleNotificationTap(RemoteMessage message) {
    debugPrint('🎯 Notification tap handled: ${message.data}');
    // Burada istediğiniz sayfaya yönlendirme yapabilirsiniz
    // Örnek: Navigator.pushNamed(context, '/notifications');
  }

  /// Local notification'a tıklanma işlemi
  static void _onNotificationTapped(NotificationResponse response) {
    debugPrint('🎯 Local notification tapped: ${response.payload}');
    // Burada istediğiniz sayfaya yönlendirme yapabilirsiniz
  }

  /// FCM Token'ını al
  static Future<String?> getToken() async {
    try {
      String? token = await _firebaseMessaging.getToken();
      debugPrint('🔑 Current FCM Token: $token');
      return token;
    } catch (e) {
      debugPrint('❌ Token alma hatası: $e');
      return null;
    }
  }

  /// Test notification gönder
  static Future<void> sendTestNotification() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          'orionhub_channel',
          'OrionHub Bildirimleri',
          channelDescription: 'OrionHub uygulaması bildirimleri',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _localNotifications.show(
      0,
      'Test Bildirimi',
      'Bu bir test bildirimidir!',
      platformChannelSpecifics,
    );

    debugPrint('📨 Test notification gönderildi');
  }
}
 