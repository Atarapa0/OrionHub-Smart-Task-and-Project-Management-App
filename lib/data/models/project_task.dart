class ProjectTask {
  final String? id;
  final String projectId;
  final String title;
  final String? description;
  final String? assignedTo; // user email
  final String? assignedBy; // user email
  final String status; // 'todo', 'in_progress', 'done'
  final String priority; // 'low', 'medium', 'high'
  final DateTime? dueDate;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  ProjectTask({
    this.id,
    required this.projectId,
    required this.title,
    this.description,
    this.assignedTo,
    this.assignedBy,
    this.status = 'todo',
    this.priority = 'medium',
    this.dueDate,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
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
      dueDate: json['due_date'] != null
          ? DateTime.parse(json['due_date'])
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
      'due_date': dueDate?.toIso8601String(),
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
    DateTime? dueDate,
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
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  bool get isCompleted => status == 'done';
  bool get isInProgress => status == 'in_progress';
  bool get isTodo => status == 'todo';

  bool get isHighPriority => priority == 'high';
  bool get isMediumPriority => priority == 'medium';
  bool get isLowPriority => priority == 'low';
}
