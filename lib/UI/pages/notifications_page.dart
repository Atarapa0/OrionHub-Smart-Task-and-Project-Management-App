import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:todo_list/data/services/notification_service.dart';
import 'package:todo_list/data/models/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();

  List<NotificationModel> _allNotifications = [];
  List<NotificationModel> _unreadNotifications = [];
  List<NotificationModel> _invitations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    try {
      setState(() => _isLoading = true);

      final notifications = await _notificationService.getUserNotifications();

      setState(() {
        _allNotifications = notifications;
        _unreadNotifications = notifications.where((n) => !n.isRead).toList();
        _invitations = notifications
            .where((n) => n.type == 'project_invitation')
            .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirimler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadNotifications();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bildirim okundu olarak işaretlenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      await _notificationService.markAllAsRead();
      await _loadNotifications();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _respondToInvitation(String invitationId, bool accept) async {
    try {
      await _notificationService.respondToProjectInvitation(
        invitationId,
        accept,
      );
      await _loadNotifications();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(accept ? 'Davet kabul edildi' : 'Davet reddedildi'),
            backgroundColor: accept ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hata: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.blue.shade600, Colors.purple.shade600],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.notifications,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Bildirimler',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    if (_unreadNotifications.isNotEmpty)
                      TextButton.icon(
                        onPressed: _markAllAsRead,
                        icon: const Icon(Icons.done_all, color: Colors.white),
                        label: const Text(
                          'Tümünü Okundu İşaretle',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_unreadNotifications.length} okunmamış bildirim',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: Colors.blue.shade600,
              unselectedLabelColor: Colors.grey.shade600,
              indicatorColor: Colors.blue.shade600,
              tabs: [
                Tab(
                  text: 'Tümü (${_allNotifications.length})',
                  icon: const Icon(Icons.all_inbox),
                ),
                Tab(
                  text: 'Okunmamış (${_unreadNotifications.length})',
                  icon: const Icon(Icons.mark_email_unread),
                ),
                Tab(
                  text: 'Davetler (${_invitations.length})',
                  icon: const Icon(Icons.group_add),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNotificationsList(_allNotifications),
                      _buildNotificationsList(_unreadNotifications),
                      _buildInvitationsList(_invitations),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(List<NotificationModel> notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Bildirim yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          return _buildNotificationCard(notifications[index]);
        },
      ),
    );
  }

  Widget _buildInvitationsList(List<NotificationModel> invitations) {
    if (invitations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.group_add_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Proje daveti yok',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invitations.length,
        itemBuilder: (context, index) {
          return _buildInvitationCard(invitations[index]);
        },
      ),
    );
  }

  Widget _buildNotificationCard(NotificationModel notification) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: notification.isRead ? 1 : 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _markAsRead(notification.id),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _getNotificationIcon(notification.type),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      notification.title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: notification.isRead
                            ? FontWeight.w500
                            : FontWeight.bold,
                        color: notification.isRead
                            ? Colors.grey.shade700
                            : Colors.black87,
                      ),
                    ),
                  ),
                  if (!notification.isRead)
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                notification.message,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    notification.timeAgo,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const Spacer(),
                  _getNotificationTypeChip(notification.type),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitationCard(NotificationModel notification) {
    final actionData = notification.actionData;
    final invitationStatus = actionData?['status'] ?? 'pending';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.group_add,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    notification.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              notification.message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  notification.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                if (invitationStatus == 'pending') ...[
                  TextButton(
                    onPressed: () =>
                        _respondToInvitation(notification.relatedId!, false),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Reddet'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () =>
                        _respondToInvitation(notification.relatedId!, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kabul Et'),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: invitationStatus == 'accepted'
                          ? Colors.green.shade100
                          : Colors.red.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      invitationStatus == 'accepted'
                          ? 'Kabul Edildi'
                          : 'Reddedildi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: invitationStatus == 'accepted'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getNotificationIcon(String type) {
    IconData icon;
    Color color;

    switch (type) {
      case 'task_reminder':
        icon = Icons.schedule;
        color = Colors.orange;
        break;
      case 'task_assigned':
        icon = Icons.assignment;
        color = Colors.blue;
        break;
      case 'project_invitation':
        icon = Icons.group_add;
        color = Colors.green;
        break;
      case 'project_added':
        icon = Icons.folder_shared;
        color = Colors.purple;
        break;
      default:
        icon = Icons.notifications;
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _getNotificationTypeChip(String type) {
    String text;
    Color color;

    switch (type) {
      case 'task_reminder':
        text = 'Hatırlatma';
        color = Colors.orange;
        break;
      case 'task_assigned':
        text = 'Görev';
        color = Colors.blue;
        break;
      case 'project_invitation':
        text = 'Davet';
        color = Colors.green;
        break;
      case 'project_added':
        text = 'Proje';
        color = Colors.purple;
        break;
      default:
        text = 'Bildirim';
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
