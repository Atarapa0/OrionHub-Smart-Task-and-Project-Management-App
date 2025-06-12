import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:todo_list/data/services/notification_service.dart';
import 'package:todo_list/data/models/notification.dart';
import 'package:todo_list/data/services/task_service.dart';
import 'package:todo_list/data/services/project_services.dart';
import 'package:todo_list/data/models/task.dart';
import 'package:todo_list/data/models/project_task.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final NotificationService _notificationService = NotificationService();
  late TaskService _taskService;
  final ProjectService _projectService = ProjectService();

  List<NotificationModel> _invitations = [];
  List<NotificationModel> _taskAssignments = []; // Görev atama bildirimleri
  List<ProjectTask> _projectTasks = [];
  List<Task> _personalTasks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _taskService = TaskService(context);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() => _isLoading = true);

      // Önce proje görev bildirimlerini oluştur ve eski davetleri temizle
      await Future.wait([
        _notificationService.createProjectTaskNotifications(),
        _notificationService.cleanupAcceptedInvitations(),
      ]);

      // Paralel olarak tüm verileri yükle
      final results = await Future.wait([
        _loadInvitations(),
        _loadTaskAssignments(), // Görev atama bildirimleri
        _loadProjectTasks(),
        _loadPersonalTasks(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _loadInvitations() async {
    final notifications = await _notificationService.getUserNotifications();
    _invitations = notifications
        .where((n) => n.type == 'project_invitation')
        .toList();
  }

  Future<void> _loadTaskAssignments() async {
    final notifications = await _notificationService.getUserNotifications();
    _taskAssignments = notifications
        .where((n) => n.type == 'task_assigned')
        .toList();
  }

  Future<void> _loadProjectTasks() async {
    final tasks = await _projectService.getUserProjectTasks();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _projectTasks = tasks.where((task) {
      if (task.dueDateTime == null) return false;

      // Sadece bugün ve geçmiş görevleri göster
      return task.dueDateTime!.isBefore(now.add(const Duration(days: 1))) &&
          task.status != 'done';
    }).toList();

    // Tarihe göre sırala (geçmiş olanlar önce)
    _projectTasks.sort((a, b) {
      if (a.dueDateTime == null && b.dueDateTime == null) return 0;
      if (a.dueDateTime == null) return 1;
      if (b.dueDateTime == null) return -1;
      return a.dueDateTime!.compareTo(b.dueDateTime!);
    });
  }

  Future<void> _loadPersonalTasks() async {
    final tasks = await _taskService.fetchTasksForCurrentUser();
    final now = DateTime.now();

    _personalTasks = tasks.where((task) {
      if (task.dueDateTime == null) return false;

      // Sadece bugün ve geçmiş görevleri göster
      return task.dueDateTime!.isBefore(now.add(const Duration(days: 1))) &&
          task.status != 'completed';
    }).toList();

    // Tarihe göre sırala (geçmiş olanlar önce)
    _personalTasks.sort((a, b) {
      if (a.dueDateTime == null && b.dueDateTime == null) return 0;
      if (a.dueDateTime == null) return 1;
      if (b.dueDateTime == null) return -1;
      return a.dueDateTime!.compareTo(b.dueDateTime!);
    });
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _notificationService.markAsRead(notificationId);
      await _loadData();
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
      await _loadData();
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
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      await _notificationService.respondToProjectInvitation(
        invitationId,
        accept,
      );

      // Loading'i kapat
      if (mounted) Navigator.pop(context);

      await _loadData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  accept ? Icons.check_circle : Icons.cancel,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  accept
                      ? 'Davet kabul edildi! Projeye katıldınız.'
                      : 'Davet reddedildi',
                ),
              ],
            ),
            backgroundColor: accept ? Colors.green : Colors.orange,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Loading'i kapat
      if (mounted) Navigator.pop(context);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text('Hata: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            duration: const Duration(seconds: 4),
          ),
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
                    if (_invitations.isNotEmpty)
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
                  '${_invitations.length} proje daveti',
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
                  text:
                      'Tümü (${_taskAssignments.length + _projectTasks.length + _personalTasks.length})',
                  icon: const Icon(Icons.all_inbox),
                ),
                Tab(
                  text: 'Görev Atamaları (${_taskAssignments.length})',
                  icon: const Icon(Icons.assignment_ind),
                ),
                Tab(
                  text: 'Proje Görevleri (${_projectTasks.length})',
                  icon: const Icon(Icons.folder_shared),
                ),
                Tab(
                  text: 'Kişisel Görevler (${_personalTasks.length})',
                  icon: const Icon(Icons.assignment),
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
                      _buildNotificationsList(
                        _taskAssignments,
                        _projectTasks,
                        _personalTasks,
                      ),
                      _buildTaskAssignmentsList(_taskAssignments),
                      _buildProjectTasksList(_projectTasks),
                      _buildPersonalTasksList(_personalTasks),
                      _buildInvitationsList(_invitations),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList(
    List<NotificationModel> taskAssignments,
    List<ProjectTask> projectTasks,
    List<Task> personalTasks,
  ) {
    if (taskAssignments.isEmpty &&
        projectTasks.isEmpty &&
        personalTasks.isEmpty) {
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount:
            taskAssignments.length + projectTasks.length + personalTasks.length,
        itemBuilder: (context, index) {
          if (index < taskAssignments.length) {
            return _buildTaskAssignmentCard(taskAssignments[index]);
          } else if (index < taskAssignments.length + projectTasks.length) {
            return _buildProjectTaskCard(
              projectTasks[index - taskAssignments.length],
            );
          } else {
            return _buildPersonalTaskCard(
              personalTasks[index -
                  taskAssignments.length -
                  projectTasks.length],
            );
          }
        },
      ),
    );
  }

  Widget _buildTaskAssignmentsList(List<NotificationModel> taskAssignments) {
    if (taskAssignments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_ind_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Görev atama bildirimi yok',
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: taskAssignments.length,
        itemBuilder: (context, index) {
          return _buildTaskAssignmentCard(taskAssignments[index]);
        },
      ),
    );
  }

  Widget _buildTaskAssignmentCard(NotificationModel notification) {
    final actionData = notification.actionData ?? {};
    final projectTitle = actionData['project_title'] ?? 'Bilinmeyen Proje';
    final taskTitle = actionData['task_title'] ?? notification.title;
    final assignedBy = actionData['assigned_by'] ?? 'Bilinmeyen';

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
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.assignment_ind,
                    color: Colors.green.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yeni Görev Atandı',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        projectTitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!notification.isRead)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade600,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              taskTitle,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              notification.message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  'Atayan: $assignedBy',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const Spacer(),
                Text(
                  _formatDate(notification.createdAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
              ],
            ),
            if (!notification.isRead) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _markAsRead(notification.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text('Okundu İşaretle'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProjectTasksList(List<ProjectTask> projectTasks) {
    if (projectTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_shared_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Proje görevleri yok',
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: projectTasks.length,
        itemBuilder: (context, index) {
          return _buildProjectTaskCard(projectTasks[index]);
        },
      ),
    );
  }

  Widget _buildPersonalTasksList(List<Task> personalTasks) {
    if (personalTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Kişisel görevler yok',
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: personalTasks.length,
        itemBuilder: (context, index) {
          return _buildPersonalTaskCard(personalTasks[index]);
        },
      ),
    );
  }

  Widget _buildProjectTaskCard(ProjectTask task) {
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
                    Icons.folder_shared,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
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
              task.description ?? 'Açıklama yok',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  task.timeStatus,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                _getProjectTaskTypeChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTaskCard(Task task) {
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
                    Icons.assignment,
                    color: Colors.blue.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
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
              task.description ?? 'Açıklama yok',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  task.timeStatus,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                _getPersonalTaskTypeChip(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getProjectTaskTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Proje',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.blue,
        ),
      ),
    );
  }

  Widget _getPersonalTaskTypeChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Kişisel',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: Colors.green,
        ),
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
              'Davet yok',
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
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: invitations.length,
        itemBuilder: (context, index) {
          return _buildInvitationCard(invitations[index]);
        },
      ),
    );
  }

  Widget _buildInvitationCard(NotificationModel invitation) {
    final actionData = invitation.actionData;
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
                    invitation.title,
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
              invitation.message,
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  invitation.timeAgo,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                ),
                const Spacer(),
                _getInvitationStatusChip(invitationStatus),
              ],
            ),
            const SizedBox(height: 16),
            // Kabul Et / Reddet Butonları (sadece pending durumunda)
            if (invitationStatus == 'pending') ...[
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _respondToInvitation(invitation.relatedId!, false),
                      icon: const Icon(Icons.close, size: 18),
                      label: const Text('Reddet'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: BorderSide(color: Colors.red.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _respondToInvitation(invitation.relatedId!, true),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Kabul Et'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Durum mesajı (kabul edilmiş/reddedilmiş)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: invitationStatus == 'accepted'
                      ? Colors.green.shade50
                      : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: invitationStatus == 'accepted'
                        ? Colors.green.shade200
                        : Colors.red.shade200,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      invitationStatus == 'accepted'
                          ? Icons.check_circle
                          : Icons.cancel,
                      color: invitationStatus == 'accepted'
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      invitationStatus == 'accepted'
                          ? 'Davet Kabul Edildi'
                          : 'Davet Reddedildi',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: invitationStatus == 'accepted'
                            ? Colors.green.shade700
                            : Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _getInvitationStatusChip(String status) {
    Color color;
    String text;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        text = 'Kabul Edildi';
        break;
      case 'rejected':
        color = Colors.red;
        text = 'Reddedildi';
        break;
      case 'expired':
        color = Colors.grey;
        text = 'Süresi Doldu';
        break;
      default:
        color = Colors.orange;
        text = 'Bekliyor';
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

  String _formatDate(DateTime dateTime) {
    try {
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays} gün önce';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} saat önce';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} dakika önce';
      } else {
        return 'Az önce';
      }
    } catch (e) {
      return 'Bilinmiyor';
    }
  }
}
