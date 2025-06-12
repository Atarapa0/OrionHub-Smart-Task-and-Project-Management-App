class NotificationModel {
  final String id;
  final String userEmail;
  final String title;
  final String message;
  final String type;
  final String? relatedId;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final Map<String, dynamic>? actionData;
  final String timeAgo;

  NotificationModel({
    required this.id,
    required this.userEmail,
    required this.title,
    required this.message,
    required this.type,
    this.relatedId,
    required this.isRead,
    required this.createdAt,
    this.expiresAt,
    this.actionData,
    required this.timeAgo,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      userEmail: json['user_email'],
      title: json['title'],
      message: json['message'],
      type: json['type'],
      relatedId: json['related_id'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'])
          : null,
      actionData: json['action_data'] != null
          ? Map<String, dynamic>.from(json['action_data'])
          : null,
      timeAgo: json['time_ago'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_email': userEmail,
      'title': title,
      'message': message,
      'type': type,
      'related_id': relatedId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
      'action_data': actionData,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userEmail,
    String? title,
    String? message,
    String? type,
    String? relatedId,
    bool? isRead,
    DateTime? createdAt,
    DateTime? expiresAt,
    Map<String, dynamic>? actionData,
    String? timeAgo,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userEmail: userEmail ?? this.userEmail,
      title: title ?? this.title,
      message: message ?? this.message,
      type: type ?? this.type,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      actionData: actionData ?? this.actionData,
      timeAgo: timeAgo ?? this.timeAgo,
    );
  }
}
