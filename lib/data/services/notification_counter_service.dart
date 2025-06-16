import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    _notificationCountController.close();
  }

  static const String _keyUnreadCount = 'unread_notification_count';

  /// Uygulama başlatıldığında sayacı yükle
  Future<void> loadUnreadCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _notificationCount = prefs.getInt(_keyUnreadCount) ?? 0;
      _notificationCountController.add(_notificationCount);
      debugPrint('📊 Okunmamış bildirim sayısı yüklendi: $_notificationCount');
    } catch (e) {
      debugPrint('❌ Bildirim sayısı yükleme hatası: $e');
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
