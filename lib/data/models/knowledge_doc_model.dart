class KnowledgeDocModel {
  final String id;
  final String title;
  final String content;
  final List<double>? embedding;
  final String? category;
  final String? sourceId;
  final String? sourceType;
  final String? branch;
  final int? year;
  final String? addedBy;
  final DateTime createdAt;

  const KnowledgeDocModel({
    required this.id,
    required this.title,
    required this.content,
    this.embedding,
    this.category,
    this.sourceId,
    this.sourceType,
    this.branch,
    this.year,
    this.addedBy,
    required this.createdAt,
  });

  factory KnowledgeDocModel.fromJson(Map<String, dynamic> json) {
    return KnowledgeDocModel(
      id: json['id'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      category: json['category'] as String?,
      sourceId: json['source_id'] as String?,
      sourceType: json['source_type'] as String?,
      branch: json['branch'] as String?,
      year: json['year'] as int?,
      addedBy: json['added_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'content': content,
        'category': category,
        'source_id': sourceId,
        'source_type': sourceType,
        'branch': branch,
        'year': year,
        'added_by': addedBy,
        'created_at': createdAt.toIso8601String(),
      };

  KnowledgeDocModel copyWith({
    String? title,
    String? content,
    String? category,
    String? branch,
    int? year,
  }) {
    return KnowledgeDocModel(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      embedding: embedding,
      category: category ?? this.category,
      sourceId: sourceId,
      sourceType: sourceType,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      addedBy: addedBy,
      createdAt: createdAt,
    );
  }
}
