class ProfileModel {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String branch;
  final int? year;
  final String? avatarUrl;
  final DateTime createdAt;

  const ProfileModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.branch,
    this.year,
    this.avatarUrl,
    required this.createdAt,
  });

  bool get isAdmin => role == 'admin';

  String get firstName => fullName.split(' ').first;

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      role: json['role'] as String,
      branch: json['branch'] as String,
      year: json['year'] as int?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'email': email,
        'role': role,
        'branch': branch,
        'year': year,
        'avatar_url': avatarUrl,
        'created_at': createdAt.toIso8601String(),
      };

  ProfileModel copyWith({
    String? fullName,
    String? branch,
    int? year,
    String? avatarUrl,
  }) {
    return ProfileModel(
      id: id,
      fullName: fullName ?? this.fullName,
      email: email,
      role: role,
      branch: branch ?? this.branch,
      year: year ?? this.year,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
    );
  }
}
