import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
import 'package:todo_list/UI/widget/add_task_dialog.dart';
import 'package:todo_list/UI/widget/task_item.dart';
import 'package:todo_list/UI/widget/progress_card.dart';
import 'package:todo_list/data/models/task.dart';
import 'package:todo_list/data/services/task_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final TaskService _taskService;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Real-time görev listesi
  List<Task> _currentTasks = [];
  bool _isLoading = false;

  // Filtreleme için değişkenler
  String _selectedPriority = 'all';
  String _selectedStatus = 'all';
  String _selectedDateFilter = 'all';

  @override
  void initState() {
    super.initState();
    _taskService = TaskService(context);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();

    // İlk görev yüklemesi
    _loadTasks();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Real-time görev yükleme
  Future<void> _loadTasks() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final tasks = await _getFilteredTasks();
      setState(() {
        _currentTasks = tasks;
        _isLoading = false;
      });
      debugPrint('✅ ${tasks.length} görev yüklendi (real-time)');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      debugPrint('❌ Görev yükleme hatası: $e');
    }
  }

  // Filtrelenmiş görevleri getiren method
  Future<List<Task>> _getFilteredTasks() async {
    List<Task> allTasks = await _taskService.fetchTasksForCurrentUser();

    // Öncelik filtresi
    if (_selectedPriority != 'all') {
      allTasks = allTasks
          .where((task) => task.priority == _selectedPriority)
          .toList();
    }

    // Durum filtresi
    if (_selectedStatus != 'all') {
      allTasks = allTasks
          .where((task) => task.status == _selectedStatus)
          .toList();
    }

    // Tarih filtresi
    if (_selectedDateFilter != 'all') {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      switch (_selectedDateFilter) {
        case 'today':
          allTasks = allTasks.where((task) {
            if (task.dueDate == null) return false;
            final taskDate = DateTime(
              task.dueDate!.year,
              task.dueDate!.month,
              task.dueDate!.day,
            );
            return taskDate == today;
          }).toList();
          break;
        case 'overdue':
          allTasks = allTasks.where((task) {
            if (task.dueDateTime == null) return false;
            return task.dueDateTime!.isBefore(now) &&
                task.status != 'completed';
          }).toList();
          break;
        case 'upcoming':
          allTasks = allTasks.where((task) {
            if (task.dueDateTime == null) return false;
            return task.dueDateTime!.isAfter(now);
          }).toList();
          break;
        case 'no_date':
          allTasks = allTasks
              .where((task) => task.dueDateTime == null)
              .toList();
          break;
      }
    }

    return allTasks;
  }

  // Filtreleri sıfırlayan method
  void _clearFilters() {
    setState(() {
      _selectedPriority = 'all';
      _selectedStatus = 'all';
      _selectedDateFilter = 'all';
    });
    _loadTasks();
  }

  // Görev ekleme dialog'unu gösteren method
  void _showAddTaskDialog() {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AddTaskDialog(
          taskService: _taskService,
          onTaskAdded: (Task newTask) {
            // Real-time güncelleme: Yeni görevi listeye ekle
            setState(() {
              _currentTasks.insert(0, newTask);
            });

            debugPrint('✅ Yeni görev real-time eklendi: ${newTask.title}');
          },
        );
      },
    );
  }

  // Görev durumunu değiştiren method
  Future<void> _toggleTaskDone(Task task) async {
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';

    try {
      await _taskService.updateTaskStatus(task.id!, newStatus);

      // Real-time güncelleme: Görev durumunu güncelle
      setState(() {
        final index = _currentTasks.indexWhere((t) => t.id == task.id);
        if (index != -1) {
          _currentTasks[index] = _currentTasks[index].copyWith(
            status: newStatus,
          );
        }
      });

      debugPrint(
        '✅ Görev durumu real-time güncellendi: ${task.title} -> $newStatus',
      );
    } catch (e) {
      debugPrint('Görev durum güncelleme hatası: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev durumu güncellenirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Görev silme method
  Future<void> _deleteTask(Task task) async {
    try {
      debugPrint(
        'Görev silme işlemi başlatılıyor - Task ID: ${task.id} (tip: ${task.id.runtimeType})',
      );
      debugPrint('Task başlığı: ${task.title}');

      await _taskService.deleteTask(task.id!);

      // Real-time güncelleme: Görevi listeden kaldır
      setState(() {
        _currentTasks.removeWhere((t) => t.id == task.id);
      });

      debugPrint('✅ Görev real-time silindi: ${task.title}');
    } catch (e) {
      debugPrint('Görev silme hatası: $e');
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Görev silinirken hata oluştu: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomAppBar(),
      body: Column(
        children: [
          // Bugünkü İlerleme Kartı
          ProgressCard(tasks: _currentTasks),

          // Filtre ve Arama Bölümü
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(13),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Filtre Butonları
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _showFilterDialog,
                        icon: const Icon(Icons.filter_list, size: 20),
                        label: const Text('Filtrele'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(Icons.clear_all, size: 20),
                      label: const Text('Temizle'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),

          // Görev Listesi
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _currentTasks.isEmpty
                ? _buildEmptyState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _currentTasks.length,
                      itemBuilder: (context, index) {
                        final task = _currentTasks[index];
                        return TaskItem(
                          task: task,
                          index: index,
                          onToggle: () => _toggleTaskDone(task),
                          onDelete: () => _deleteTask(task),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Görev Ekle',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      bottomNavigationBar: const BottomNavigationController(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.task_alt, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Henüz görev yok',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'İlk görevini eklemek için + butonuna bas',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showAddTaskDialog,
            icon: const Icon(Icons.add),
            label: const Text('İlk Görevini Ekle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Filtre dialog'unu gösteren method
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(Icons.filter_list, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  const Text('Filtrele'),
                  const Spacer(),
                  TextButton(
                    onPressed: () {
                      setDialogState(() {
                        _selectedPriority = 'all';
                        _selectedStatus = 'all';
                        _selectedDateFilter = 'all';
                      });
                    },
                    child: const Text('Temizle'),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Öncelik Filtresi
                    const Text(
                      'Öncelik',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip(
                          'all',
                          'Tümü',
                          _selectedPriority,
                          (value) =>
                              setDialogState(() => _selectedPriority = value),
                        ),
                        _buildFilterChip(
                          'high',
                          'Yüksek',
                          _selectedPriority,
                          (value) =>
                              setDialogState(() => _selectedPriority = value),
                        ),
                        _buildFilterChip(
                          'medium',
                          'Orta',
                          _selectedPriority,
                          (value) =>
                              setDialogState(() => _selectedPriority = value),
                        ),
                        _buildFilterChip(
                          'low',
                          'Düşük',
                          _selectedPriority,
                          (value) =>
                              setDialogState(() => _selectedPriority = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Durum Filtresi
                    const Text(
                      'Durum',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip(
                          'all',
                          'Tümü',
                          _selectedStatus,
                          (value) =>
                              setDialogState(() => _selectedStatus = value),
                        ),
                        _buildFilterChip(
                          'pending',
                          'Bekliyor',
                          _selectedStatus,
                          (value) =>
                              setDialogState(() => _selectedStatus = value),
                        ),
                        _buildFilterChip(
                          'completed',
                          'Tamamlandı',
                          _selectedStatus,
                          (value) =>
                              setDialogState(() => _selectedStatus = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Tarih Filtresi
                    const Text(
                      'Tarih',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        _buildFilterChip(
                          'all',
                          'Tümü',
                          _selectedDateFilter,
                          (value) =>
                              setDialogState(() => _selectedDateFilter = value),
                        ),
                        _buildFilterChip(
                          'today',
                          'Bugün',
                          _selectedDateFilter,
                          (value) =>
                              setDialogState(() => _selectedDateFilter = value),
                        ),
                        _buildFilterChip(
                          'overdue',
                          'Gecikmiş',
                          _selectedDateFilter,
                          (value) =>
                              setDialogState(() => _selectedDateFilter = value),
                        ),
                        _buildFilterChip(
                          'upcoming',
                          'Yaklaşan',
                          _selectedDateFilter,
                          (value) =>
                              setDialogState(() => _selectedDateFilter = value),
                        ),
                        _buildFilterChip(
                          'no_date',
                          'Tarihi Yok',
                          _selectedDateFilter,
                          (value) =>
                              setDialogState(() => _selectedDateFilter = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _loadTasks(); // Filtreleri uygula
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Uygula'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFilterChip(
    String value,
    String label,
    String selectedValue,
    Function(String) onSelected,
  ) {
    final isSelected = selectedValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onSelected(value),
      selectedColor: Colors.blue.shade100,
      checkmarkColor: Colors.blue.shade700,
    );
  }
}
