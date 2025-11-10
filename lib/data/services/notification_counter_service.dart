import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationCounterService {
  static final NotificationCounterService _instance =
      NotificationCounterService._internal();
  factory NotificationCounterService() => _instance;
  NotificationCounterService._internal();

  // Stream controller for notification count
  final StreamController<int> _notificationCountController =
      StreamController<int>.broadcast();

  // Current notification count
  int _notificationCount = 0;

  // Supabase real-time subscription
  RealtimeChannel? _realtimeSubscription;

  // Getter for stream
  Stream<int> get notificationCountStream =>
      _notificationCountController.stream;

  // Getter for current count
  int get notificationCount => _notificationCount;

  // Increment notification count
  void incrementNotificationCount() {
    _notificationCount++;
    _notificationCountController.add(_notificationCount);
  }

  // Reset notification count
  void resetNotificationCount() {
    _notificationCount = 0;
    _notificationCountController.add(_notificationCount);
  }

  // Set specific count
  void setNotificationCount(int count) {
    _notificationCount = count;
    _notificationCountController.add(_notificationCount);
  }

  // Dispose
  void dispose() {
    _realtimeSubscription?.unsubscribe();
    _notificationCountController.close();
  }

  static const String _keyUnreadCount = 'unread_notification_count';

  /// Uygulama başlatıldığında sayacı yükle
  Future<void> loadUnreadCount() async {
    try {
      // Önce veritabanından gerçek sayıyı al
      await _loadFromDatabase();

      // Sonra SharedPreferences'tan yedek sayıyı al
      final prefs = await SharedPreferences.getInstance();
      final savedCount = prefs.getInt(_keyUnreadCount) ?? 0;

      // Eğer veritabanından sayı alınamazsa, kaydedilen sayıyı kullan
      if (_notificationCount == 0 && savedCount > 0) {
        _notificationCount = savedCount;
      }

      _notificationCountController.add(_notificationCount);
      debugPrint('📊 Okunmamış bildirim sayısı yüklendi: $_notificationCount');
    } catch (e) {
      debugPrint('❌ Bildirim sayısı yükleme hatası: $e');
    }
  }

  /// Veritabanından gerçek okunmamış bildirim sayısını al
  Future<void> _loadFromDatabase() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userEmail = prefs.getString('loggedInUserEmail');

      if (userEmail == null) {
        debugPrint('📊 Kullanıcı email bulunamadı, sayaç 0');
        return;
      }

      // Supabase'den okunmamış bildirim sayısını al
      final supabase = Supabase.instance.client;
      final response = await supabase
          .from('notifications')
          .select('id')
          .eq('user_email', userEmail)
          .eq('is_read', false);

      _notificationCount = response.length;
      debugPrint(
        '📊 Veritabanından okunmamış bildirim sayısı: $_notificationCount',
      );

      // SharedPreferences'a kaydet
      await prefs.setInt(_keyUnreadCount, _notificationCount);

      // Real-time subscription'ı başlat
      await _startRealtimeSubscription(userEmail);
    } catch (e) {
      debugPrint('❌ Veritabanından bildirim sayısı alma hatası: $e');
    }
  }

  /// Real-time bildirim dinlemeyi başlat
  Future<void> _startRealtimeSubscription(String userEmail) async {
    try {
      // Önceki subscription'ı kapat
      await _realtimeSubscription?.unsubscribe();

      final supabase = Supabase.instance.client;
      _realtimeSubscription = supabase
          .channel('notifications_$userEmail')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'user_email',
              value: userEmail,
            ),
            callback: (payload) async {
              debugPrint('🔔 Real-time: Yeni bildirim geldi!');
              debugPrint('📦 Payload: ${payload.toString()}');

              // Sadece bildirim sayacını artır (local notification gösterme)
              incrementUnreadCount();
              debugPrint('📊 Real-time: Sadece sayaç artırıldı');
            },
          )
          .subscribe();

      debugPrint('📡 Real-time bildirim dinleme başlatıldı: $userEmail');
    } catch (e) {
      debugPrint('❌ Real-time subscription hatası: $e');
    }
  }

  /// Yeni bildirim geldiğinde sayacı artır
  Future<void> incrementUnreadCount() async {
    try {
      _notificationCount++;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUnreadCount, _notificationCount);
      _notificationCountController.add(_notificationCount);
      debugPrint('📈 Bildirim sayısı artırıldı: $_notificationCount');
    } catch (e) {
      debugPrint('❌ Bildirim sayısı artırma hatası: $e');
    }
  }

  /// Bildirimler sayfası açıldığında sayacı sıfırla
  Future<void> clearUnreadCount() async {
    try {
      _notificationCount = 0;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUnreadCount, 0);
      _notificationCountController.add(_notificationCount);
      debugPrint('🔄 Bildirim sayısı sıfırlandı');
    } catch (e) {
      debugPrint('❌ Bildirim sayısı sıfırlama hatası: $e');
    }
  }

  /// Belirli sayıda bildirim okundu olarak işaretle
  Future<void> markAsRead(int count) async {
    try {
      _notificationCount = (_notificationCount - count).clamp(
        0,
        _notificationCount,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyUnreadCount, _notificationCount);
      _notificationCountController.add(_notificationCount);
      debugPrint(
        '✅ $count bildirim okundu olarak işaretlendi. Kalan: $_notificationCount',
      );
    } catch (e) {
      debugPrint('❌ Bildirim okundu işaretleme hatası: $e');
    }
  }
}
