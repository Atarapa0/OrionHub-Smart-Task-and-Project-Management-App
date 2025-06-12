import 'package:flutter/material.dart';
import 'package:todo_list/UI/widget/bottom_navigation_controller.dart';
import 'package:todo_list/UI/widget/custom_app_bar.dart';
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

  // FutureBuilder'ı yeniden tetiklemek için key
  Key _futureBuilderKey = UniqueKey();

  // Future instance'ını kontrol etmek için
  late Future<List<Task>> _tasksFuture;

  // Filtreleme için değişkenler
  String _selectedPriority = 'all';
  String _selectedStatus = 'all';
  String _selectedDateFilter = 'all'; // 'all', 'today', 'overdue', 'upcoming'

  @override
  void initState() {
    super.initState();
    _taskService = TaskService(context);
    _tasksFuture = _getFilteredTasks();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Görevleri yeniden yüklemek için method
  void _refreshTasks() {
    setState(() {
      _futureBuilderKey = UniqueKey();
      _tasksFuture = _getFilteredTasks();
    });
    debugPrint('Tasks Future yenilendi - Key: $_futureBuilderKey');
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
    _refreshTasks();
  }

  // Filtre popup'ını gösteren method
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
                          'Tümü',
                          _selectedPriority == 'all',
                          () {
                            setDialogState(() => _selectedPriority = 'all');
                          },
                        ),
                        _buildFilterChip(
                          'Acil',
                          _selectedPriority == 'urgent',
                          () {
                            setDialogState(() => _selectedPriority = 'urgent');
                          },
                          color: Colors.red,
                        ),
                        _buildFilterChip(
                          'Yüksek',
                          _selectedPriority == 'high',
                          () {
                            setDialogState(() => _selectedPriority = 'high');
                          },
                          color: Colors.orange,
                        ),
                        _buildFilterChip(
                          'Orta',
                          _selectedPriority == 'medium',
                          () {
                            setDialogState(() => _selectedPriority = 'medium');
                          },
                          color: Colors.yellow.shade700,
                        ),
                        _buildFilterChip(
                          'Düşük',
                          _selectedPriority == 'low',
                          () {
                            setDialogState(() => _selectedPriority = 'low');
                          },
                          color: Colors.green,
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
                        _buildFilterChip('Tümü', _selectedStatus == 'all', () {
                          setDialogState(() => _selectedStatus = 'all');
                        }),
                        _buildFilterChip(
                          'Bekliyor',
                          _selectedStatus == 'pending',
                          () {
                            setDialogState(() => _selectedStatus = 'pending');
                          },
                          color: Colors.blue,
                        ),
                        _buildFilterChip(
                          'Devam Ediyor',
                          _selectedStatus == 'in_progress',
                          () {
                            setDialogState(
                              () => _selectedStatus = 'in_progress',
                            );
                          },
                          color: Colors.orange,
                        ),
                        _buildFilterChip(
                          'Tamamlandı',
                          _selectedStatus == 'completed',
                          () {
                            setDialogState(() => _selectedStatus = 'completed');
                          },
                          color: Colors.green,
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
                          'Tümü',
                          _selectedDateFilter == 'all',
                          () {
                            setDialogState(() => _selectedDateFilter = 'all');
                          },
                        ),
                        _buildFilterChip(
                          'Bugün',
                          _selectedDateFilter == 'today',
                          () {
                            setDialogState(() => _selectedDateFilter = 'today');
                          },
                          color: Colors.blue,
                        ),
                        _buildFilterChip(
                          'Süresi Geçmiş',
                          _selectedDateFilter == 'overdue',
                          () {
                            setDialogState(
                              () => _selectedDateFilter = 'overdue',
                            );
                          },
                          color: Colors.red,
                        ),
                        _buildFilterChip(
                          'Gelecek',
                          _selectedDateFilter == 'upcoming',
                          () {
                            setDialogState(
                              () => _selectedDateFilter = 'upcoming',
                            );
                          },
                          color: Colors.purple,
                        ),
                        _buildFilterChip(
                          'Tarihsiz',
                          _selectedDateFilter == 'no_date',
                          () {
                            setDialogState(
                              () => _selectedDateFilter = 'no_date',
                            );
                          },
                          color: Colors.grey,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('İptal'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _refreshTasks();
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

  // Filtre chip'i oluşturan helper method
  Widget _buildFilterChip(
    String label,
    bool isSelected,
    VoidCallback onTap, {
    Color? color,
  }) {
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : (color ?? Colors.grey.shade700),
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: color ?? Colors.blue.shade600,
      backgroundColor: Colors.grey.shade100,
      checkmarkColor: Colors.white,
    );
  }

  void _showAddTaskDialog() {
    String title = '';
    String description = '';
    String priority = 'medium';
    String category = '';
    DateTime? selectedDate;
    TimeOfDay? selectedTime;

    showDialog(
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
                            'Yeni Görev Ekle',
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

                                  Task newTask = Task(
                                    title: title.trim(),
                                    description: description.trim().isEmpty
                                        ? null
                                        : description.trim(),
                                    status: 'pending',
                                    priority: priority,
                                    category: category.trim().isEmpty
                                        ? null
                                        : category.trim(),
                                    dueDate: selectedDate,
                                    dueTime: dueTimeString,
                                  );

                                  try {
                                    await _taskService.insertTask(newTask);
                                    if (!mounted) return;
                                    _refreshTasks();
                                    if (context.mounted) {
                                      Navigator.of(context).pop();
                                    }

                                    // Başarı mesajı
                                    if (mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            '${newTask.title} eklendi',
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
                                    if (mounted) {
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

  Future<void> _toggleTaskDone(Task task) async {
    // Status'u değiştir
    final newStatus = task.status == 'completed' ? 'pending' : 'completed';

    try {
      await _taskService.updateTaskStatus(task.id!, newStatus);
      _refreshTasks();
    } catch (e) {
      debugPrint('Görev durum güncelleme hatası: $e');
      if (mounted) {
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

  Future<void> _deleteTask(Task task) async {
    try {
      debugPrint(
        'Görev silme işlemi başlatılıyor - Task ID: ${task.id} (tip: ${task.id.runtimeType})',
      );
      debugPrint('Task başlığı: ${task.title}');

      await _taskService.deleteTask(task.id!);

      debugPrint('Görev başarıyla silindi, liste yenileniyor...');
      _refreshTasks();
    } catch (e) {
      debugPrint('Görev silme hatası: $e');
      if (mounted) {
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

  Widget _buildTaskItem(Task task, int index) {
    return Dismissible(
      key: Key(task.id.toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_forever, color: Colors.white, size: 28),
      ),
      onDismissed: (direction) {
        _deleteTask(task);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${task.title} silindi'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: task.status == 'completed'
              ? Colors.green.shade50
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: task.status == 'completed'
                ? Colors.green.shade200
                : Colors.grey.shade200,
            width: 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 8,
          ),
          leading: GestureDetector(
            onTap: () => _toggleTaskDone(task),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.status == 'completed'
                    ? Colors.green.shade500
                    : Colors.transparent,
                border: Border.all(
                  color: task.status == 'completed'
                      ? Colors.green.shade500
                      : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: task.status == 'completed'
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
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
                        color: task.status == 'completed'
                            ? Colors.grey.shade600
                            : Colors.black87,
                        decoration: task.status == 'completed'
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
              // Kategori ve zaman bilgisi
              Row(
                children: [
                  if (task.category != null && task.category!.isNotEmpty) ...[
                    Icon(Icons.category, size: 12, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      task.category!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  if (task.dueDateTime != null) ...[
                    Icon(
                      Icons.schedule,
                      size: 12,
                      color:
                          task.dueDateTime!.isBefore(DateTime.now()) &&
                              task.status != 'completed'
                          ? Colors.red.shade500
                          : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      task.timeStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            task.dueDateTime!.isBefore(DateTime.now()) &&
                                task.status != 'completed'
                            ? Colors.red.shade600
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          subtitle: task.description != null && task.description!.isNotEmpty
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    task.description!,
                    style: TextStyle(
                      fontSize: 14,
                      color: task.status == 'completed'
                          ? Colors.grey.shade500
                          : Colors.grey.shade700,
                      decoration: task.status == 'completed'
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
              : null,
          trailing: Icon(
            Icons.drag_handle,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ),
      ),
    );
  }

  // Öncelik rengini döndüren helper method
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

  // Öncelik metnini döndüren helper method
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

  bool _hasActiveFilters() {
    return _selectedPriority != 'all' ||
        _selectedStatus != 'all' ||
        _selectedDateFilter != 'all';
  }

  String _getPriorityDisplayText(String priority) {
    switch (priority) {
      case 'urgent':
        return 'Acil';
      case 'high':
        return 'Yüksek';
      case 'medium':
        return 'Orta';
      case 'low':
        return 'Düşük';
      default:
        return 'Orta';
    }
  }

  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return 'Bekliyor';
      case 'in_progress':
        return 'Devam Ediyor';
      case 'completed':
        return 'Tamamlandı';
      default:
        return 'Bekliyor';
    }
  }

  String _getDateFilterDisplayText(String dateFilter) {
    switch (dateFilter) {
      case 'today':
        return 'Bugün';
      case 'overdue':
        return 'Süresi Geçmiş';
      case 'upcoming':
        return 'Gelecek';
      case 'no_date':
        return 'Tarihsiz';
      default:
        return 'Tümü';
    }
  }

  Widget _buildActiveFilterChip(String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(
          label,
          style: TextStyle(
            color: Colors.blue.shade700,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        selected: true,
        onSelected: (_) => onTap(),
        selectedColor: Colors.blue.shade100,
        backgroundColor: Colors.blue.shade50,
        deleteIcon: Icon(Icons.close, size: 16, color: Colors.blue.shade600),
        onDeleted: onTap,
        side: BorderSide(color: Colors.blue.shade300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: const CustomAppBar(),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İlerleme Kartı
              FutureBuilder<List<Task>>(
                key: _futureBuilderKey,
                future: _tasksFuture,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final tasks = snapshot.data!;
                    final completedTasks = tasks
                        .where((task) => task.status == 'completed')
                        .length;
                    final totalTasks = tasks.length;

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.blue.shade400,
                            Colors.purple.shade400,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blue.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              _hasActiveFilters()
                                  ? Icons.filter_alt
                                  : Icons.analytics_outlined,
                              color: Colors.white,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _hasActiveFilters()
                                      ? 'Filtrelenmiş Görevler'
                                      : 'Bugünkü İlerlemeniz',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$completedTasks / $totalTasks görev tamamlandı',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: 14,
                                  ),
                                ),
                                if (_hasActiveFilters()) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    'Filtre uygulandı',
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.8),
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                LinearProgressIndicator(
                                  value: totalTasks > 0
                                      ? completedTasks / totalTasks
                                      : 0,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 50,
                                height: 50,
                                child: CircularProgressIndicator(
                                  value: totalTasks > 0
                                      ? completedTasks / totalTasks
                                      : 0,
                                  backgroundColor: Colors.white.withOpacity(
                                    0.3,
                                  ),
                                  valueColor:
                                      const AlwaysStoppedAnimation<Color>(
                                        Colors.white,
                                      ),
                                  strokeWidth: 4,
                                ),
                              ),
                              Text(
                                totalTasks > 0
                                    ? '${((completedTasks / totalTasks) * 100).round()}%'
                                    : '0%',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Görevler Başlığı ve Filtreler
              Row(
                children: [
                  Icon(Icons.task_alt, color: Colors.grey.shade700, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Görevleriniz',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  const Spacer(),
                  // Aktif filtre göstergesi
                  if (_hasActiveFilters()) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.filter_alt,
                            size: 14,
                            color: Colors.blue.shade600,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Filtreli',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // Filtre butonu
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: IconButton(
                      onPressed: _showFilterDialog,
                      icon: Icon(
                        Icons.tune,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                      tooltip: 'Filtrele',
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                    ),
                  ),
                ],
              ),

              // Aktif filtreler gösterimi
              if (_hasActiveFilters()) ...[
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_selectedPriority != 'all')
                        _buildActiveFilterChip(
                          'Öncelik: ${_getPriorityDisplayText(_selectedPriority)}',
                          () {
                            setState(() => _selectedPriority = 'all');
                            _refreshTasks();
                          },
                        ),
                      if (_selectedStatus != 'all')
                        _buildActiveFilterChip(
                          'Durum: ${_getStatusDisplayText(_selectedStatus)}',
                          () {
                            setState(() => _selectedStatus = 'all');
                            _refreshTasks();
                          },
                        ),
                      if (_selectedDateFilter != 'all')
                        _buildActiveFilterChip(
                          'Tarih: ${_getDateFilterDisplayText(_selectedDateFilter)}',
                          () {
                            setState(() => _selectedDateFilter = 'all');
                            _refreshTasks();
                          },
                        ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 16),
                        label: const Text('Tümünü Temizle'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.red.shade600,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Görevler Listesi
              Expanded(
                child: FutureBuilder<List<Task>>(
                  key: ValueKey('tasks_${_futureBuilderKey.toString()}'),
                  future: _tasksFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Colors.red.shade300,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Bir hata oluştu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.task_outlined,
                              size: 64,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Henüz görev yok',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'İlk görevinizi eklemek için + butonuna tıklayın',
                              style: TextStyle(color: Colors.grey.shade600),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      );
                    } else {
                      final tasks = snapshot.data!;
                      return ListView.builder(
                        itemCount: tasks.length,
                        itemBuilder: (context, index) {
                          return _buildTaskItem(tasks[index], index);
                        },
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddTaskDialog,
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Yeni Görev',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: const BottomNavigationController(initialIndex: 0),
    );
  }
}
