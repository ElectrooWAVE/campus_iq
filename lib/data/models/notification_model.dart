class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String? body;
  final String? type;
  final String priority;
  final String? referenceId;
  final String? referenceType;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    this.body,
    this.type,
    required this.priority,
    this.referenceId,
    this.referenceType,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      body: json['body'] as String?,
      type: json['type'] as String?,
      priority: json['priority'] as String? ?? 'low',
      referenceId: json['reference_id'] as String?,
      referenceType: json['reference_type'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'body': body,
        'type': type,
        'priority': priority,
        'reference_id': referenceId,
        'reference_type': referenceType,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      body: body,
      type: type,
      priority: priority,
      referenceId: referenceId,
      referenceType: referenceType,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
