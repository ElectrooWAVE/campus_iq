class TimetableModel {
  final String id;
  final String title;
  final String imageUrl;
  final String storagePath;
  final String branch;
  final int year;
  final DateTime effectiveDate;
  final String? description;
  final String? postedBy;
  final DateTime createdAt;

  const TimetableModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.storagePath,
    required this.branch,
    required this.year,
    required this.effectiveDate,
    this.description,
    this.postedBy,
    required this.createdAt,
  });

  factory TimetableModel.fromJson(Map<String, dynamic> json) {
    return TimetableModel(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String,
      storagePath: json['storage_path'] as String,
      branch: json['branch'] as String,
      year: json['year'] as int,
      effectiveDate: DateTime.parse(json['effective_date'] as String),
      description: json['description'] as String?,
      postedBy: json['posted_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'image_url': imageUrl,
        'storage_path': storagePath,
        'branch': branch,
        'year': year,
        'effective_date': effectiveDate.toIso8601String().split('T')[0],
        'description': description,
        'posted_by': postedBy,
        'created_at': createdAt.toIso8601String(),
      };

  TimetableModel copyWith({
    String? title,
    String? imageUrl,
    String? storagePath,
    String? branch,
    int? year,
    DateTime? effectiveDate,
    String? description,
  }) {
    return TimetableModel(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      storagePath: storagePath ?? this.storagePath,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      description: description ?? this.description,
      postedBy: postedBy,
      createdAt: createdAt,
    );
  }
}
