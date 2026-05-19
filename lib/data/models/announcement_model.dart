class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String? imageUrl;
  final String? storagePath;
  final String priority;
  final String? branch;
  final int? year;
  final bool isPublished;
  final String? createdBy;
  final DateTime createdAt;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.imageUrl,
    this.storagePath,
    required this.priority,
    this.branch,
    this.year,
    required this.isPublished,
    this.createdBy,
    required this.createdAt,
  });

  factory AnnouncementModel.fromJson(Map<String, dynamic> json) {
    return AnnouncementModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      imageUrl: json['image_url'] as String?,
      storagePath: json['storage_path'] as String?,
      priority: json['priority'] as String? ?? 'general',
      branch: json['branch'] as String?,
      year: json['year'] as int?,
      isPublished: json['is_published'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'image_url': imageUrl,
        'storage_path': storagePath,
        'priority': priority,
        'branch': branch,
        'year': year,
        'is_published': isPublished,
        'created_by': createdBy,
        'created_at': createdAt.toIso8601String(),
      };

  AnnouncementModel copyWith({
    String? title,
    String? body,
    String? imageUrl,
    String? storagePath,
    String? priority,
    String? branch,
    int? year,
    bool? isPublished,
  }) {
    return AnnouncementModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      storagePath: storagePath ?? this.storagePath,
      priority: priority ?? this.priority,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      isPublished: isPublished ?? this.isPublished,
      createdBy: createdBy,
      createdAt: createdAt,
    );
  }
}
