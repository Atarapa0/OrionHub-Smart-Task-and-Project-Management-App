class Project {
  final String? id;
  final String title;
  final String? description;
  final String? ownerId;
  final DateTime createdAt;
  final List<Map<String, dynamic>>? projectMembers;

  Project({
    this.id,
    required this.title,
    this.description,
    this.ownerId,
    required this.createdAt,
    this.projectMembers,
  });

  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      ownerId: json['owner_id'],
      createdAt: DateTime.parse(json['created_at']),
      projectMembers: json['project_members'] != null 
          ? List<Map<String, dynamic>>.from(json['project_members'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'owner_id': ownerId,
      'created_at': createdAt.toIso8601String(),
    };
  }
}