import 'package:flutter/material.dart';

class ProjectTask {
  final String? id;
  final String projectId;
  final String title;
  final String? description;
  final String? assignedTo; // user email
  final String? assignedBy; // user email
  final String status; // 'todo', 'in_progress', 'done'
  final String priority; // 'low', 'medium', 'high', 'urgent'
  final String? category;
  final DateTime? dueDate;
  final String? dueTime; // HH:MM formatında
  final DateTime? dueDateTime; // Birleştirilmiş tarih ve saat
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  String? projectTitle; // Proje başlığı (bildirimler için)

  ProjectTask({
    this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedBy,
    this.status = 'todo',
    this.priority = 'medium',
    this.category,
    this.dueDate,
    this.dueTime,
    this.dueDateTime,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.projectTitle,
  });

  factory ProjectTask.fromJson(Map<String, dynamic> json) {
    return ProjectTask(
      id: json['id'],
      projectId: json['project_id'],
      title: json['title'],
      description: json['description'],
      assignedTo: json['assigned_to'],
      assignedBy: json['assigned_by'],
      status: json['status'] ?? 'todo',
      priority: json['priority'] ?? 'medium',
      category: json['category'],
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
          : null,
      dueTime: json['due_time'],
      dueDateTime: json['due_datetime'] != null
          ? DateTime.parse(json['due_datetime'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'title': title,
      'description': description,
      'assigned_to': assignedTo,
      'assigned_by': assignedBy,
      'status': status,
      'priority': priority,
      'category': category,
      'due_date': dueDate?.toIso8601String().split(
        'T',
      )[0], // Sadece tarih kısmı
      'due_time': dueTime,
      'due_datetime': dueDateTime?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ProjectTask copyWith({
    String? id,
    String? projectId,
    String? title,
    String? description,
    String? assignedTo,
    String? assignedBy,
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
    return ProjectTask(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      assignedBy: assignedBy ?? this.assignedBy,
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

  // Durum kontrol metodları
  bool get isCompleted => status == 'done';
  bool get isInProgress => status == 'in_progress';
  bool get isTodo => status == 'todo';

  // Öncelik kontrol metodları
  bool get isUrgentPriority => priority == 'urgent';
  bool get isHighPriority => priority == 'high';
  bool get isMediumPriority => priority == 'medium';
  bool get isLowPriority => priority == 'low';

  // Öncelik rengi
  Color get priorityColor {
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

  // Zaman durumu
  String get timeStatus {
    if (dueDateTime == null) return 'Tarih belirlenmemiş';

    final now = DateTime.now();
    final difference = dueDateTime!.difference(now);

    if (difference.isNegative) {
      // Süresi geçmiş
      final overdueDays = difference.inDays.abs();
      final overdueHours = (difference.inHours.abs() % 24);

      if (overdueDays > 0) {
        return 'Süresi geçmiş ($overdueDays gün $overdueHours saat)';
      } else {
        return 'Süresi geçmiş ($overdueHours saat)';
      }
    } else {
      // Kalan süre
      final remainingDays = difference.inDays;
      final remainingHours = (difference.inHours % 24);

      if (remainingDays > 0) {
        return '$remainingDays gün $remainingHours saat kaldı';
      } else if (remainingHours > 0) {
        return '$remainingHours saat kaldı';
      } else {
        final remainingMinutes = difference.inMinutes;
        return '$remainingMinutes dakika kaldı';
      }
    }
  }

  // Geriye uyumluluk için
  bool get isDone => status == 'done';
}
