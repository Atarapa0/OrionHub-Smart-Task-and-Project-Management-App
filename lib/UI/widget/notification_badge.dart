import 'package:flutter/material.dart';
import 'package:todo_list/data/services/notification_counter_service.dart';

class NotificationBadge extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const NotificationBadge({super.key, required this.child, this.onTap});

  @override
  State<NotificationBadge> createState() => _NotificationBadgeState();
}

class _NotificationBadgeState extends State<NotificationBadge> {
  final NotificationCounterService _counterService =
      NotificationCounterService();
  int _notificationCount = 0;

  @override
  void initState() {
    super.initState();
    _counterService.loadUnreadCount();
    _notificationCount = _counterService.notificationCount;

    // Stream'i dinle
    _counterService.notificationCountStream.listen((count) {
      if (mounted) {
        setState(() {
          _notificationCount = count;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        children: [
          widget.child,
          if (_notificationCount > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                ),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                child: Text(
                  _notificationCount > 99
                      ? '99+'
                      : _notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
