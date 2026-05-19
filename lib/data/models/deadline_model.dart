class DeadlineModel {
  final String id;
  final String title;
  final String? description;
  final DateTime dueDate;
  final String subjectName;
  final String branch;
  final int year;
  final String priority;
  final String? createdBy;
  final DateTime createdAt;

  const DeadlineModel({
    required this.id,
    required this.title,
    this.description,
    required this.dueDate,
    required this.subjectName,
    required this.branch,
    required this.year,
    required this.priority,
    this.createdBy,
    required this.createdAt,
  });

  bool get isOverdue => dueDate.isBefore(DateTime.now());
  bool get isUrgent => dueDate.difference(DateTime.now()).inHours < 24;
  bool get isThisWeek =>
      dueDate.difference(DateTime.now()).inDays < 7 &&
      !isOverdue;

  factory DeadlineModel.fromJson(Map<String, dynamic> json) {
    return DeadlineModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      subjectName: json['subject_name'] as String,
      branch: json['branch'] as String,
      year: json['year'] as int,
      priority: json['priority'] as String? ?? 'medium',
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'due_date': dueDate.toIso8601String(),
        'subject_name': subjectName,
        'branch': branch,
        'year': year,
        'priority': priority,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  DeadlineModel copyWith({
    String? title,
    String? description,
    DateTime? dueDate,
    String? subjectName,
    String? branch,
    int? year,
    String? priority,
  }) {
    return DeadlineModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      subjectName: subjectName ?? this.subjectName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      priority: priority ?? this.priority,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
