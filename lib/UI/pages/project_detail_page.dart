import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/data/models/project.dart';
import 'package:todo_list/data/models/project_member.dart';
import 'package:todo_list/data/models/project_task.dart';
import 'package:todo_list/data/services/project_management_service.dart';
import 'package:todo_list/data/services/notification_service.dart';

class ProjectDetailPage extends StatefulWidget {
  final Project project;

  const ProjectDetailPage({super.key, required this.project});

  @override
  State<ProjectDetailPage> createState() => _ProjectDetailPageState();
}

class _ProjectDetailPageState extends State<ProjectDetailPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final ProjectManagementService _projectService = ProjectManagementService();
  final NotificationService _notificationService = NotificationService();

  List<ProjectMember> _members = [];
  List<ProjectTask> _tasks = [];
  List<Map<String, dynamic>> _invitations = [];
  Map<String, dynamic> _stats = {};
  String? _userRole;
  String? _currentUserEmail;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadProjectData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProjectData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // Önce kullanıcı email'ini al
      _currentUserEmail = await _projectService.getCurrentUserEmail();

      final results = await Future.wait([
        _projectService.getProjectMembers(widget.project.id!),
        _projectService.getProjectTasks(widget.project.id!),
        _projectService.getProjectStats(widget.project.id!),
        _projectService.getUserRoleInProject(widget.project.id!),
        _projectService.getProjectInvitations(widget.project.id!),
      ]);

      if (mounted) {
        setState(() {
          _members = results[0] as List<ProjectMember>;
          _tasks = results[1] as List<ProjectTask>;
          _stats = results[2] as Map<String, dynamic>;
          _userRole = results[3] as String?;
          _invitations = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Veri yükleme hatası: $e');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veri yüklenirken hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  bool get _canManageMembers => _userRole == 'owner' || _userRole == 'admin';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.title),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.blue.shade600, Colors.purple.shade600],
            ),
          ),
        ),
        foregroundColor: Colors.white,
        actions: [
          // Sadece proje sahibi için silme butonu
          if (_userRole == 'owner')
            PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete_forever, color: Colors.red.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Projeyi Sil',
                        style: TextStyle(color: Colors.red.shade600),
                      ),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteProjectDialog();
                }
              },
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Proje Başlığı ve İstatistikler
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
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.project.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (widget.project.description != null)
                                  Text(
                                    widget.project.description!,
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.9,
                                      ),
                                      fontSize: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _userRole?.toUpperCase() ?? 'MEMBER',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      // İstatistik Kartları
                      Row(
                        children: [
                          _buildStatCard(
                            'Görevler',
                            '${_stats['completed_tasks'] ?? 0}/${_stats['total_tasks'] ?? 0}',
                            Icons.task_alt,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Üyeler',
                            '${_stats['total_members'] ?? 0}',
                            Icons.people,
                          ),
                          const SizedBox(width: 12),
                          _buildStatCard(
                            'Tamamlanma',
                            '%${_stats['completion_rate'] ?? 0}',
                            Icons.trending_up,
                          ),
                        ],
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
                    tabs: const [
                      Tab(text: 'Görevler', icon: Icon(Icons.task)),
                      Tab(text: 'Üyeler', icon: Icon(Icons.people)),
                      Tab(text: 'İstatistikler', icon: Icon(Icons.analytics)),
                    ],
                  ),
                ),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildTasksTab(),
                      _buildMembersTab(),
                      _buildStatsTab(),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: const BottomNavigationController(initialIndex: 1),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksTab() {
    return Column(
      children: [
        // Görev Ekleme Butonu (sadece proje sahibi için)
        if (_userRole == 'owner')
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddTaskDialog,
              icon: const Icon(Icons.add),
              label: const Text('Yeni Görev Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

        // Bilgi mesajı
        if (_userRole != 'owner')
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue.shade600, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Sadece size atanan görevleri görüyorsunuz. Kendi görevlerinizi tamamlayabilirsiniz.',
                    style: TextStyle(color: Colors.blue.shade700, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),

        // Görevler Listesi
        Expanded(
          child: _tasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.task_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        _userRole == 'owner'
                            ? 'Henüz görev yok'
                            : 'Size atanmış görev yok',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _tasks.length,
                  itemBuilder: (context, index) {
                    return _buildTaskCard(_tasks[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTaskCard(ProjectTask task) {
    final currentUserEmail = _getCurrentUserEmail();
    // Sadece görevin sahibi kendi görevini tamamlayabilir
    final canCompleteTask = task.assignedTo == currentUserEmail;
    // Proje sahibi tüm görevleri yönetebilir (atama, silme)
    final canManageTask = _userRole == 'owner';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: task.isCompleted ? Colors.green.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: task.isCompleted
              ? Colors.green.shade200
              : Colors.grey.shade200,
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: GestureDetector(
          onTap: canCompleteTask ? () => _updateTaskStatus(task) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted
                  ? Colors.green.shade500
                  : Colors.transparent,
              border: Border.all(
                color: task.isCompleted
                    ? Colors.green.shade500
                    : (canCompleteTask
                          ? Colors.grey.shade400
                          : Colors.grey.shade300),
                width: 2,
              ),
            ),
            child: task.isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 16)
                : (canCompleteTask
                      ? null
                      : Icon(
                          Icons.visibility,
                          color: Colors.grey.shade400,
                          size: 12,
                        )),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: task.isCompleted
                          ? Colors.grey.shade600
                          : (canCompleteTask
                                ? Colors.black87
                                : Colors.grey.shade600),
                      decoration: task.isCompleted
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                  ),
                ),
                // Öncelik göstergesi
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: _getPriorityColor(task.priority),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getPriorityText(task.priority),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Kategori, atama ve zaman bilgisi
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                if (task.category != null && task.category!.isNotEmpty) ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category,
                          size: 12,
                          color: Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.category!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.assignedTo != null) ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 140),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.assignedTo == currentUserEmail
                              ? Icons.person
                              : Icons.person_outline,
                          size: 12,
                          color: task.assignedTo == currentUserEmail
                              ? Colors.blue.shade500
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.assignedTo == currentUserEmail
                                ? 'Bana Atandı'
                                : task.assignedTo!.split('@')[0],
                            style: TextStyle(
                              fontSize: 12,
                              color: task.assignedTo == currentUserEmail
                                  ? Colors.blue.shade600
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                if (task.dueDateTime != null) ...[
                  Container(
                    constraints: const BoxConstraints(maxWidth: 120),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 12,
                          color:
                              task.dueDateTime!.isBefore(DateTime.now()) &&
                                  !task.isCompleted
                              ? Colors.red.shade500
                              : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.timeStatus,
                            style: TextStyle(
                              fontSize: 12,
                              color:
                                  task.dueDateTime!.isBefore(DateTime.now()) &&
                                      !task.isCompleted
                                  ? Colors.red.shade600
                                  : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            // Yönetici görünümü etiketi
            if (!canCompleteTask && task.assignedTo != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _userRole == 'owner'
                      ? Colors.orange.shade100
                      : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _userRole == 'owner'
                          ? Icons.admin_panel_settings
                          : Icons.visibility_off,
                      size: 10,
                      color: _userRole == 'owner'
                          ? Colors.orange.shade600
                          : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      _userRole == 'owner'
                          ? 'Yönetici Görünümü'
                          : 'Sadece Görüntüleme',
                      style: TextStyle(
                        color: _userRole == 'owner'
                            ? Colors.orange.shade600
                            : Colors.grey.shade600,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        subtitle: task.description != null && task.description!.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  task.description!,
                  style: TextStyle(
                    fontSize: 14,
                    color: task.isCompleted
                        ? Colors.grey.shade500
                        : (canCompleteTask
                              ? Colors.grey.shade700
                              : Colors.grey.shade500),
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              )
            : null,
        trailing: canManageTask
            ? PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'assign',
                    child: const Row(
                      children: [
                        Icon(Icons.person_add),
                        SizedBox(width: 8),
                        Text('Ata'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: const Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Sil'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'assign') {
                    _showAssignTaskDialog(task);
                  } else if (value == 'delete') {
                    _deleteTask(task);
                  }
                },
              )
            : Icon(Icons.drag_handle, color: Colors.grey.shade400, size: 20),
      ),
    );
  }

  Widget _buildMembersTab() {
    final pendingInvitations = _invitations
        .where((inv) => inv['status'] == 'pending')
        .toList();

    return Column(
      children: [
        // Üye Ekleme Butonu
        if (_canManageMembers)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            child: ElevatedButton.icon(
              onPressed: _showAddMemberDialog,
              icon: const Icon(Icons.person_add),
              label: const Text('Üye Ekle'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

        // Üyeler ve Davetler Listesi
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Aktif Üyeler Başlığı
              if (_members.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(Icons.people, color: Colors.blue.shade600, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Aktif Üyeler (${_members.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Üyeler Listesi
                ...(_members.map((member) => _buildMemberCard(member))),
              ],

              // Bekleyen Davetler Başlığı
              if (pendingInvitations.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.schedule,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Bekleyen Davetler (${pendingInvitations.length})',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bekleyen Davetler Listesi
                ...(pendingInvitations.map(
                  (invitation) => _buildInvitationCard(invitation),
                )),
              ],

              // Boş durum mesajı
              if (_members.isEmpty && pendingInvitations.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Henüz üye yok',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Projeye üye eklemek için yukarıdaki butonu kullanın',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMemberCard(ProjectMember member) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.shade100,
          child: Text(
            member.userName.isNotEmpty ? member.userName[0].toUpperCase() : 'U',
            style: TextStyle(
              color: Colors.blue.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(member.userName),
        subtitle: Text(member.userEmail),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(member.role),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _getRoleText(member.role),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_canManageMembers && !member.isOwner)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'role',
                    child: const Row(
                      children: [
                        Icon(Icons.edit),
                        SizedBox(width: 8),
                        Text('Rol Değiştir'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'remove',
                    child: const Row(
                      children: [
                        Icon(Icons.remove_circle, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Çıkar'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'role') {
                    _showChangeRoleDialog(member);
                  } else if (value == 'remove') {
                    _removeMember(member);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvitationCard(Map<String, dynamic> invitation) {
    final invitedEmail = invitation['invited_email'] ?? 'Bilinmeyen';
    final createdAt = DateTime.parse(invitation['created_at']);
    final timeAgo = _getTimeAgo(createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.orange.shade100,
          child: Icon(Icons.schedule, color: Colors.orange.shade700),
        ),
        title: Text(invitedEmail),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Davet gönderildi'),
            Text(
              timeAgo,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Bekliyor',
                style: TextStyle(
                  color: Colors.orange.shade700,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (_canManageMembers)
              PopupMenuButton(
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'cancel',
                    child: const Row(
                      children: [
                        Icon(Icons.cancel, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Daveti İptal Et'),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'cancel') {
                    _cancelInvitation(invitation['id']);
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
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
  }

  Future<void> _cancelInvitation(String invitationId) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Daveti İptal Et'),
          content: const Text(
            'Bu daveti iptal etmek istediğinizden emin misiniz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Vazgeç'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('İptal Et'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        await _projectService.cancelInvitation(invitationId);
        await _loadProjectData();

        if (mounted && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Davet iptal edildi'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Davet iptal edilirken hata: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildStatsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Bilgi mesajı
          if (_userRole != 'owner')
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bar_chart,
                    color: Colors.orange.shade600,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bu istatistikler sadece size atanan görevleri kapsar.',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Görev Durumu Grafiği
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _userRole == 'owner'
                        ? 'Proje Görev Durumu'
                        : 'Görevlerim Durumu',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildProgressBar(
                    'Tamamlanan',
                    _stats['completed_tasks'] ?? 0,
                    _stats['total_tasks'] ?? 1,
                    Colors.green,
                  ),
                  _buildProgressBar(
                    'Devam Eden',
                    _stats['in_progress_tasks'] ?? 0,
                    _stats['total_tasks'] ?? 1,
                    Colors.orange,
                  ),
                  _buildProgressBar(
                    'Bekleyen',
                    _stats['todo_tasks'] ?? 0,
                    _stats['total_tasks'] ?? 1,
                    Colors.blue,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Diğer İstatistikler
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Genel İstatistikler',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildStatRow(
                    'Yüksek Öncelikli Görevler',
                    '${_stats['high_priority_tasks'] ?? 0}',
                  ),
                  _buildStatRow(
                    'Geciken Görevler',
                    '${_stats['overdue_tasks'] ?? 0}',
                  ),
                  if (_userRole == 'owner')
                    _buildStatRow(
                      'Toplam Üye',
                      '${_stats['total_members'] ?? 0}',
                    ),
                  _buildStatRow(
                    'Tamamlanma Oranı',
                    '%${_stats['completion_rate'] ?? 0}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int total, Color color) {
    final percentage = total > 0 ? value / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [Text(label), Text('$value/$total')],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // Dialog ve İşlem Metodları
  Future<void> _showAddTaskDialog() async {
    String title = '';
    String description = '';
    String priority = 'medium';
    String category = '';
    String? assignedTo;
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue.shade50, Colors.purple.shade50],
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade100,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.add_task,
                              color: Colors.blue.shade700,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Text(
                            'Yeni Proje Görevi Ekle',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Başlık
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Görev Başlığı *',
                          prefixIcon: const Icon(Icons.title),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => title = value,
                      ),
                      const SizedBox(height: 16),

                      // Açıklama
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Açıklama (İsteğe bağlı)',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        onChanged: (value) => description = value,
                      ),
                      const SizedBox(height: 16),

                      // Öncelik
                      DropdownButtonFormField<String>(
                        value: priority,
                        decoration: InputDecoration(
                          labelText: 'Öncelik',
                          prefixIcon: const Icon(Icons.priority_high),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'low', child: Text('Düşük')),
                          DropdownMenuItem(
                            value: 'medium',
                            child: Text('Orta'),
                          ),
                          DropdownMenuItem(
                            value: 'high',
                            child: Text('Yüksek'),
                          ),
                          DropdownMenuItem(
                            value: 'urgent',
                            child: Text('Acil'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() {
                              priority = value;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Kategori
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Kategori (İsteğe bağlı)',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => category = value,
                      ),
                      const SizedBox(height: 16),

                      // Atanan Kişi
                      DropdownButtonFormField<String>(
                        value: assignedTo,
                        decoration: InputDecoration(
                          labelText: 'Atanan Kişi',
                          prefixIcon: const Icon(Icons.person_add),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Atanmamış'),
                          ),
                          ..._members.map(
                            (member) => DropdownMenuItem(
                              value: member.userEmail,
                              child: Text(member.userName),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setDialogState(() => assignedTo = value),
                      ),
                      const SizedBox(height: 16),

                      // Tarih Seçimi
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (date != null) {
                            setDialogState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today),
                              const SizedBox(width: 12),
                              Text(
                                selectedDate == null
                                    ? 'Bitiş Tarihi Seç (İsteğe bağlı)'
                                    : 'Bitiş Tarihi: ${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}',
                                style: TextStyle(
                                  color: selectedDate == null
                                      ? Colors.grey.shade600
                                      : Colors.black87,
                                ),
                              ),
                              const Spacer(),
                              if (selectedDate != null)
                                IconButton(
                                  icon: const Icon(Icons.clear, size: 20),
                                  onPressed: () {
                                    setDialogState(() {
                                      selectedDate = null;
                                      selectedTime = null;
                                    });
                                  },
                                ),
                            ],
                          ),
                        ),
                      ),

                      // Saat Seçimi (sadece tarih seçildiyse)
                      if (selectedDate != null) ...[
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: selectedTime ?? TimeOfDay.now(),
                            );
                            if (time != null) {
                              setDialogState(() {
                                selectedTime = time;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time),
                                const SizedBox(width: 12),
                                Text(
                                  selectedTime == null
                                      ? 'Bitiş Saati Seç (İsteğe bağlı)'
                                      : 'Bitiş Saati: ${selectedTime!.format(context)}',
                                  style: TextStyle(
                                    color: selectedTime == null
                                        ? Colors.grey.shade600
                                        : Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                if (selectedTime != null)
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      setDialogState(() {
                                        selectedTime = null;
                                      });
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'İptal',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                if (title.trim().isNotEmpty) {
                                  final context = dialogContext;

                                  // Tarih ve saat bilgilerini hazırla
                                  String? dueTimeString;
                                  if (selectedTime != null) {
                                    dueTimeString =
                                        '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}';
                                  }

                                  final task = ProjectTask(
                                    projectId: widget.project.id!,
                                    title: title.trim(),
                                    description: description.trim().isEmpty
                                        ? null
                                        : description.trim(),
                                    priority: priority,
                                    category: category.trim().isEmpty
                                        ? null
                                        : category.trim(),
                                    assignedTo: assignedTo,
                                    dueDate: selectedDate,
                                    dueTime: dueTimeString,
                                  );

                                  try {
                                    final newTaskId = await _projectService
                                        .addProjectTask(task);
                                    if (!mounted) return;
                                    await _loadProjectData();

                                    // Eğer birine atandıysa bildirim oluştur
                                    if (assignedTo != null &&
                                        newTaskId != null) {
                                      // Atayan kişinin adını al
                                      final assignerMember = _members
                                          .firstWhere(
                                            (m) =>
                                                m.userEmail ==
                                                _currentUserEmail,
                                            orElse: () => ProjectMember(
                                              projectId: widget.project.id!,
                                              userEmail:
                                                  _currentUserEmail ?? '',
                                              userName: 'Bilinmeyen',
                                              role: 'owner',
                                            ),
                                          );

                                      debugPrint(
                                        '🔔 Yeni görev için bildirim oluşturuluyor...',
                                      );
                                      await _notificationService
                                          .createTaskAssignmentNotification(
                                            assignedToEmail: assignedTo!,
                                            taskTitle: task.title,
                                            projectTitle: widget.project.title,
                                            taskId: newTaskId,
                                            projectId: widget.project.id!,
                                            assignedByName:
                                                assignerMember.userName,
                                          );
                                    }

                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }

                                    // Başarı mesajı
                                    if (mounted && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${task.title} eklendi',
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    debugPrint('❌ Görev ekleme hatası: $e');
                                    if (mounted && context.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text('Hata: $e'),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                          ),
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Ekle',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showAddMemberDialog() async {
    String searchQuery = '';
    List<Map<String, dynamic>> searchResults = [];
    bool isSearching = false;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Üye Ekle'),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Kullanıcı Ara',
                    hintText: 'Email veya isim girin',
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) async {
                    searchQuery = value;
                    if (value.length >= 2) {
                      setDialogState(() => isSearching = true);
                      try {
                        final results = await _projectService
                            .searchRegisteredUsers(value);
                        // Zaten proje üyesi olanları filtrele
                        final filteredResults = results.where((user) {
                          return !_members.any(
                            (member) => member.userEmail == user['email'],
                          );
                        }).toList();

                        if (mounted) {
                          setDialogState(() {
                            searchResults = filteredResults;
                            isSearching = false;
                          });
                        }
                      } catch (e) {
                        if (mounted) {
                          setDialogState(() {
                            searchResults = [];
                            isSearching = false;
                          });
                        }
                      }
                    } else {
                      setDialogState(() {
                        searchResults = [];
                        isSearching = false;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                if (isSearching)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  )
                else if (searchQuery.length >= 2 && searchResults.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(20),
                    child: Text(
                      'Kullanıcı bulunamadı veya tüm kullanıcılar zaten üye',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                else if (searchResults.isNotEmpty)
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListView.builder(
                      itemCount: searchResults.length,
                      itemBuilder: (context, index) {
                        final user = searchResults[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.blue.shade100,
                            child: Text(
                              user['name']
                                  .toString()
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(user['name']),
                          subtitle: Text(user['email']),
                          trailing: const Icon(
                            Icons.add_circle,
                            color: Colors.green,
                          ),
                          onTap: () async {
                            // Context referanslarını önceden al
                            final navigator = Navigator.of(context);
                            final scaffoldMessenger = ScaffoldMessenger.of(
                              context,
                            );

                            try {
                              await _projectService.addMemberToProject(
                                projectId: widget.project.id!,
                                userEmail: user['email'],
                                userName: user['name'],
                              );

                              if (mounted) {
                                navigator.pop();
                                await _loadProjectData();
                                if (mounted) {
                                  scaffoldMessenger.showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        '${user['name']} projeye eklendi',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              }
                            } catch (e) {
                              if (mounted) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('Hata: $e'),
                                    backgroundColor: Colors.red,
                                    duration: const Duration(seconds: 3),
                                  ),
                                );
                              }
                            }
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAssignTaskDialog(ProjectTask task) async {
    String? selectedMember = task.assignedTo;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Görev Ata'),
          content: DropdownButtonFormField<String>(
            value: selectedMember,
            decoration: const InputDecoration(labelText: 'Atanan Kişi'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Atanmamış')),
              ..._members.map(
                (member) => DropdownMenuItem(
                  value: member.userEmail,
                  child: Text(member.userName),
                ),
              ),
            ],
            onChanged: (value) => setDialogState(() => selectedMember = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Context referanslarını önceden al
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  await _projectService.assignTask(task.id!, selectedMember);

                  // Eğer birine atandıysa bildirim oluştur
                  if (selectedMember != null &&
                      selectedMember != task.assignedTo &&
                      task.id != null) {
                    // Atayan kişinin adını al
                    final assignerMember = _members.firstWhere(
                      (m) => m.userEmail == _currentUserEmail,
                      orElse: () => ProjectMember(
                        projectId: widget.project.id!,
                        userEmail: _currentUserEmail ?? '',
                        userName: 'Bilinmeyen',
                        role: 'owner',
                      ),
                    );

                    debugPrint(
                      '🔔 Mevcut görev için bildirim oluşturuluyor...',
                    );
                    await _notificationService.createTaskAssignmentNotification(
                      assignedToEmail: selectedMember!,
                      taskTitle: task.title,
                      projectTitle: widget.project.title,
                      taskId: task.id!,
                      projectId: widget.project.id!,
                      assignedByName: assignerMember.userName,
                    );
                  }

                  if (mounted) {
                    navigator.pop();
                    await _loadProjectData();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Görev atandı'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Ata'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showChangeRoleDialog(ProjectMember member) async {
    String selectedRole = member.role;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Rol Değiştir'),
          content: DropdownButtonFormField<String>(
            value: selectedRole,
            decoration: const InputDecoration(labelText: 'Rol'),
            items: const [
              DropdownMenuItem(value: 'member', child: Text('Üye')),
              DropdownMenuItem(value: 'admin', child: Text('Yönetici')),
            ],
            onChanged: (value) =>
                setDialogState(() => selectedRole = value ?? 'member'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                // Context referanslarını önceden al
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  await _projectService.updateMemberRole(
                    member.id!,
                    selectedRole,
                  );
                  if (mounted) {
                    navigator.pop();
                    await _loadProjectData();
                    if (mounted) {
                      scaffoldMessenger.showSnackBar(
                        const SnackBar(
                          content: Text('Rol güncellendi'),
                          backgroundColor: Colors.green,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: Colors.red,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                }
              },
              child: const Text('Güncelle'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _updateTaskStatus(ProjectTask task) async {
    final newStatus = task.isCompleted ? 'todo' : 'done';

    try {
      await _projectService.updateTaskStatus(task.id!, newStatus);
      if (mounted) {
        await _loadProjectData();
      }
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Hata: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _deleteTask(ProjectTask task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Görevi Sil'),
        content: Text(
          '${task.title} görevini silmek istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Context referanslarını önceden al
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await _projectService.deleteProjectTask(task.id!);
        await _loadProjectData();
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Görev silindi'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _removeMember(ProjectMember member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Üyeyi Çıkar'),
        content: Text(
          '${member.userName} üyesini projeden çıkarmak istediğinizden emin misiniz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Çıkar'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Context referanslarını önceden al
      final scaffoldMessenger = ScaffoldMessenger.of(context);

      try {
        await _projectService.removeMemberFromProject(member.id!);
        await _loadProjectData();
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            const SnackBar(
              content: Text('Üye çıkarıldı'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          scaffoldMessenger.showSnackBar(
            SnackBar(
              content: Text('Hata: $e'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteProjectDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red.shade600),
            const SizedBox(width: 8),
            const Text('Projeyi Sil'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '"${widget.project.title}" projesini silmek istediğinizden emin misiniz?',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.warning_amber,
                        color: Colors.red.shade600,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Bu işlem geri alınamaz!',
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Tüm proje görevleri silinecek\n• Tüm proje üyeleri çıkarılacak\n• Tüm proje verileri kaybolacak',
                    style: TextStyle(color: Colors.red.shade600, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Projeyi Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      // Loading göster
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        await _projectService.deleteProject(widget.project.id!);

        if (mounted) {
          // Loading'i kapat
          Navigator.pop(context);

          // Proje listesine geri dön
          Navigator.pop(context);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.white),
                    const SizedBox(width: 8),
                    Text('"${widget.project.title}" projesi silindi'),
                  ],
                ),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
        }
      } catch (e) {
        if (mounted) {
          // Loading'i kapat
          Navigator.pop(context);

          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.error, color: Colors.white),
                    const SizedBox(width: 8),
                    Expanded(child: Text('Proje silinemedi: $e')),
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
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'urgent':
        return Colors.red.shade500;
      case 'high':
        return Colors.orange.shade500;
      case 'medium':
        return Colors.yellow.shade600;
      case 'low':
        return Colors.green.shade500;
      default:
        return Colors.grey.shade500;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
      case 'urgent':
        return 'ACİL';
      case 'high':
        return 'YÜKSEK';
      case 'medium':
        return 'ORTA';
      case 'low':
        return 'DÜŞÜK';
      default:
        return 'ORTA';
    }
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case 'owner':
        return Colors.purple;
      case 'admin':
        return Colors.blue;
      case 'member':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRoleText(String role) {
    switch (role) {
      case 'owner':
        return 'SAHİP';
      case 'admin':
        return 'YÖNETİCİ';
      case 'member':
        return 'ÜYE';
      default:
        return 'ÜYE';
    }
  }

  // Mevcut kullanıcının email'ini al
  String? _getCurrentUserEmail() {
    return _currentUserEmail;
  }
}
