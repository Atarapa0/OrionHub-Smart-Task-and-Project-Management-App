class Task {
  final String? id;
  final String? userId;
  final String title;
  final String? description;
  final String status; // 'pending', 'in_progress', 'completed'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String? category;

  // Tarih ve saat alanları
  final DateTime? dueDate;
  final String? dueTime; // "HH:mm" formatında
  final DateTime? dueDateTime; // Hesaplanmış tam tarih-saat

  // Sistem tarihleri
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  Task({
    this.id,
    this.userId,
    required this.title,
    this.description,
    this.status = 'pending',
    this.priority = 'medium',
    this.category,
    this.dueDate,
    this.dueTime,
    this.dueDateTime,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
  });

  // Geriye uyumluluk için isDone getter'ı
  bool get isDone => status == 'completed';

  // Kalan süreyi hesaplayan method
  String get timeStatus {
    if (dueDateTime == null) return 'Tarih belirlenmemiş';

    final now = DateTime.now();
    final difference = dueDateTime!.difference(now);

    if (difference.isNegative) {
      final overdue = now.difference(dueDateTime!);
      final days = overdue.inDays;
      final hours = overdue.inHours % 24;
      return 'Süresi geçmiş ($days gün $hours saat)';
    } else {
      final days = difference.inDays;
      final hours = difference.inHours % 24;
      return 'Kalan süre: $days gün $hours saat';
    }
  }

  // Öncelik rengini döndüren method
  String get priorityColor {
    switch (priority) {
      case 'urgent':
        return '#FF0000'; // Kırmızı
      case 'high':
        return '#FF8C00'; // Turuncu
      case 'medium':
        return '#FFD700'; // Sarı
      case 'low':
        return '#32CD32'; // Yeşil
      default:
        return '#FFD700';
    }
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id']?.toString(),
      userId: map['user_id']?.toString(),
      title: map['title'] ?? '',
      description: map['description'],
      status: map['status'] ?? 'pending',
      priority: map['priority'] ?? 'medium',
      category: map['category'],
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      dueTime: map['due_time']?.toString(),
      dueDateTime: map['due_datetime'] != null
          ? DateTime.parse(map['due_datetime'])
          : null,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'status': status,
      'priority': priority,
      'category': category,
      'due_date': dueDate?.toIso8601String().split(
        'T',
      )[0], // Sadece tarih kısmı
      'due_time': dueTime,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  // Task'ı kopyalayan method (güncelleme için)
  Task copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? status,
    String? priority,
    String? category,
    DateTime? dueDate,
    String? dueTime,
    DateTime? dueDateTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
  }) {
    return Task(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      dueDate: dueDate ?? this.dueDate,
      dueTime: dueTime ?? this.dueTime,
      dueDateTime: dueDateTime ?? this.dueDateTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
