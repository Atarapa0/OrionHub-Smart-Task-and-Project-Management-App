class ProjectMember {
  final String? id;
  final String projectId;
  final String userEmail;
  final String userName;
  final String role; // 'owner', 'admin', 'member'
  final DateTime? joinedAt;
  final String? invitedBy;
  final String status; // 'active', 'pending', 'removed'

  ProjectMember({
    this.id,
    required this.projectId,
    required this.userEmail,
    required this.userName,
    this.role = 'member',
    this.joinedAt,
    this.invitedBy,
    this.status = 'active',
  });

  factory ProjectMember.fromJson(Map<String, dynamic> json) {
    return ProjectMember(
      id: json['id'],
      projectId: json['project_id'],
      userEmail: json['user_email'],
      userName: json['user_name'],
      role: json['role'] ?? 'member',
      joinedAt: json['joined_at'] != null
          ? DateTime.parse(json['joined_at'])
          : null,
      invitedBy: json['invited_by'],
      status: json['status'] ?? 'active',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'project_id': projectId,
      'user_email': userEmail,
      'user_name': userName,
      'role': role,
      'joined_at': joinedAt?.toIso8601String(),
      'invited_by': invitedBy,
      'status': status,
    };
  }

  ProjectMember copyWith({
    String? id,
    String? projectId,
    String? userEmail,
    String? userName,
    String? role,
    DateTime? joinedAt,
    String? invitedBy,
    String? status,
  }) {
    return ProjectMember(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      userEmail: userEmail ?? this.userEmail,
      userName: userName ?? this.userName,
      role: role ?? this.role,
      joinedAt: joinedAt ?? this.joinedAt,
      invitedBy: invitedBy ?? this.invitedBy,
      status: status ?? this.status,
    );
  }

  bool get isOwner => role == 'owner';
  bool get isAdmin => role == 'admin';
  bool get canManageMembers => role == 'owner' || role == 'admin';
}
