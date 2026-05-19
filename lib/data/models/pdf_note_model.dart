class PdfNoteModel {
  final String id;
  final String title;
  final String? description;
  final String fileUrl;
  final String storagePath;
  final String fileName;
  final String subjectName;
  final String branch;
  final int year;
  final String? uploadedBy;
  final DateTime createdAt;

  const PdfNoteModel({
    required this.id,
    required this.title,
    this.description,
    required this.fileUrl,
    required this.storagePath,
    required this.fileName,
    required this.subjectName,
    required this.branch,
    required this.year,
    this.uploadedBy,
    required this.createdAt,
  });

  factory PdfNoteModel.fromJson(Map<String, dynamic> json) {
    return PdfNoteModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      fileUrl: json['file_url'] as String,
      storagePath: json['storage_path'] as String,
      fileName: json['file_name'] as String,
      subjectName: json['subject_name'] as String,
      branch: json['branch'] as String,
      year: json['year'] as int,
      uploadedBy: json['uploaded_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'file_url': fileUrl,
        'storage_path': storagePath,
        'file_name': fileName,
        'subject_name': subjectName,
        'branch': branch,
        'year': year,
        'uploaded_by': uploadedBy,
        'created_at': createdAt.toIso8601String(),
      };

  PdfNoteModel copyWith({
    String? title,
    String? description,
    String? fileUrl,
    String? storagePath,
    String? fileName,
    String? subjectName,
    String? branch,
    int? year,
  }) {
    return PdfNoteModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      fileUrl: fileUrl ?? this.fileUrl,
      storagePath: storagePath ?? this.storagePath,
      fileName: fileName ?? this.fileName,
      subjectName: subjectName ?? this.subjectName,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      uploadedBy: uploadedBy,
      createdAt: createdAt,
    );
  }
}
