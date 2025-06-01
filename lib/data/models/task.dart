class Task {
  final String? id;
  final String? userId;
  final String title;
  final String? description;
  bool isDone;
  final DateTime? createdAt;

  Task({
    this.id,
    this.userId,
    required this.title,
    this.description,
    required this.isDone,
    this.createdAt,
  });

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'],
      description: map['description'],
      isDone: map['is_done'],
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'is_done': isDone,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}