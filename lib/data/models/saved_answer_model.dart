class SavedAnswerModel {
  final String id;
  final String studentId;
  final String question;
  final String answer;
  final DateTime savedAt;

  const SavedAnswerModel({
    required this.id,
    required this.studentId,
    required this.question,
    required this.answer,
    required this.savedAt,
  });

  factory SavedAnswerModel.fromJson(Map<String, dynamic> json) {
    return SavedAnswerModel(
      id: json['id'] as String,
      studentId: json['student_id'] as String,
      question: json['question'] as String,
      answer: json['answer'] as String,
      savedAt: DateTime.parse(json['saved_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'student_id': studentId,
        'question': question,
        'answer': answer,
        'saved_at': savedAt.toIso8601String(),
      };
}
