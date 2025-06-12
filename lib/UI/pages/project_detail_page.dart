import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/data/models/project.dart';
import 'package:todo_list/data/models/project_member.dart';
import 'package:todo_list/data/models/project_task.dart';
import 'package:todo_list/data/services/project_management_service.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';

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

  List<ProjectMember> _members = [];
  List<ProjectTask> _tasks = [];
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
      ]);

      if (mounted) {
        setState(() {
          _members = results[0] as List<ProjectMember>;
          _tasks = results[1] as List<ProjectTask>;
          _stats = results[2] as Map<String, dynamic>;
          _userRole = results[3] as String?;
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
      appBar: const CustomAppBar(),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: GestureDetector(
          onTap: canCompleteTask ? () => _updateTaskStatus(task) : null,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: task.isCompleted ? Colors.green : Colors.transparent,
              border: Border.all(
                color: task.isCompleted
                    ? Colors.green
                    : (canCompleteTask ? Colors.grey : Colors.grey.shade300),
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
        title: Text(
          task.title,
          style: TextStyle(
            decoration: task.isCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
            color: canCompleteTask ? null : Colors.grey.shade600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (task.description != null)
              Text(
                task.description!,
                style: TextStyle(
                  color: canCompleteTask ? null : Colors.grey.shade500,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              children: [
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
                const SizedBox(width: 8),
                if (task.assignedTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: task.assignedTo == currentUserEmail
                          ? Colors.blue.shade100
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (task.assignedTo == currentUserEmail)
                          Icon(
                            Icons.person,
                            size: 12,
                            color: Colors.blue.shade700,
                          ),
                        if (task.assignedTo == currentUserEmail)
                          const SizedBox(width: 2),
                        Text(
                          task.assignedTo == currentUserEmail
                              ? 'Bana Atandı'
                              : task.assignedTo!.split('@')[0],
                          style: TextStyle(
                            color: task.assignedTo == currentUserEmail
                                ? Colors.blue.shade700
                                : Colors.grey.shade600,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (!canCompleteTask && task.assignedTo != null)
                  Container(
                    margin: const EdgeInsets.only(left: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
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
            ),
          ],
        ),
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
            : null,
      ),
    );
  }

  Widget _buildMembersTab() {
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

        // Üyeler Listesi
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _members.length,
            itemBuilder: (context, index) {
              return _buildMemberCard(_members[index]);
            },
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

  Widget _buildStatsTab() {
    return Padding(
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
    String? assignedTo;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Yeni Görev Ekle'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: 'Görev Başlığı'),
                onChanged: (value) => title = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: 'Açıklama'),
                onChanged: (value) => description = value,
              ),
              DropdownButtonFormField<String>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Öncelik'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Düşük')),
                  DropdownMenuItem(value: 'medium', child: Text('Orta')),
                  DropdownMenuItem(value: 'high', child: Text('Yüksek')),
                ],
                onChanged: (value) =>
                    setDialogState(() => priority = value ?? 'medium'),
              ),
              DropdownButtonFormField<String>(
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
                onChanged: (value) => setDialogState(() => assignedTo = value),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (title.isNotEmpty) {
                  // Context referanslarını önceden al
                  final navigator = Navigator.of(context);
                  final scaffoldMessenger = ScaffoldMessenger.of(context);

                  final task = ProjectTask(
                    projectId: widget.project.id!,
                    title: title,
                    description: description.isEmpty ? null : description,
                    priority: priority,
                    assignedTo: assignedTo,
                  );

                  try {
                    await _projectService.addProjectTask(task);
                    if (mounted) {
                      navigator.pop();
                      await _loadProjectData();
                      if (mounted) {
                        scaffoldMessenger.showSnackBar(
                          const SnackBar(
                            content: Text('Görev eklendi'),
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
                }
              },
              child: const Text('Ekle'),
            ),
          ],
        ),
      ),
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
      if (mounted) {
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

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityText(String priority) {
    switch (priority) {
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
